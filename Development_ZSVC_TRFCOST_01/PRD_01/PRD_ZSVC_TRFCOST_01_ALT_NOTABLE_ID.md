# PRD (Alternatif) — ZSVC_TRFCOST_01: Direct Email Notification Budget Minus Tanpa Z-Table, Tanpa User Status, Tanpa SLG1

| | |
|---|---|
| **Program** | `ZSVC_TRFCOST_01` (Report existing — JCS Cost Transfer / Reman Service) |
| **Pemilik** | SVC / Cost Control (IT/IS) |
| **Status** | Draft untuk Review — Rev. 3 (menambahkan reference implementation `SEND_EMAIL_BCS` aktual) |
| **Relasi ke PRD Lain** | Alternatif dari `PRD_ZSVC_TRFCOST_01_ID.md` (staging table) dan versi sebelumnya dari dokumen ini (user status + SLG1). Dokumen ini **menghapus keduanya**. |

---

## 1. Ringkasan Eksekutif

Desain ini adalah versi **paling minimal**: tidak ada Z-table, tidak ada setup User Status/Status Profile baru, dan tidak ada application log SLG1. Program `ZSVC_TRFCOST_01` hanya ditambah **satu titik hook** — begitu budget-check menghasilkan `SALDO < 0` untuk WO dengan `AUART = 'PRT'`, email langsung dikirim ke PDH. Tidak ada mekanisme pencatatan status "sudah dinotif" — setiap kali job jalan dan WO itu masih minus, email **akan terkirim lagi** (idempotensi diserahkan ke frekuensi jadwal job, bukan ditangani program).

**Kenapa ini valid sebagai opsi:** kalau business hanya butuh "PDH langsung tahu begitu ada budget minus", tanpa perlu histori/audit trail maupun kontrol anti-spam yang canggih, maka semua object tambahan (tabel, status profile, log object) memang tidak diperlukan. Trade-off-nya ada di §6.

**Yang baru di Rev. 3:** FORM `SEND_EMAIL_BCS` sebelumnya ditulis sebagai kerangka generik ("reuse Layer 4 email builder existing"). Sekarang diganti dengan **implementasi konkret** yang sudah dipakai/divalidasi (§4.4) — termasuk sender address resmi `mail_sap@unitedtractors.com` dan konfirmasi status kirim via `MESSAGE s000`.

---

## 2. Scope

### 2.1 Di Dalam Scope
- Hook langsung di budget-check block existing `ZSVC_TRFCOST_01` — **tidak ada tabel baru, tidak ada status baru, tidak ada log object baru**.
- Filter: hanya WO dengan `AUART = 'PRT'`.
- Kirim email ke PDH setiap kali job mendeteksi `SALDO < 0` untuk WO tersebut (bisa berulang di run berikutnya selama masih minus — lihat §6 Trade-off).

### 2.2 Di Luar Scope
- Tidak ada dedup/anti-spam mechanism (tidak ada tabel maupun status untuk melacak "sudah dinotif").
- Tidak ada audit trail/histori tersimpan di sistem (selain job log standar SM37 bawaan background job).
- Tidak ada digest/rekap — 1 email per WO per kejadian terdeteksi.
- Tidak mengubah logika budget calculation maupun approval gate existing.

---

## 3. Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | Saat background job `ZSVC_TRFCOST_01` berjalan dan `SALDO < 0` untuk WO dengan `AUART = 'PRT'`, sistem mengirim email ke PDH **pada saat itu juga**. |
| FR-02 | WO dengan `AUART` selain `PRT` tidak diproses sama sekali oleh logika ini. |
| FR-03 | Kegagalan kirim email untuk 1 WO (`cx_bcs`) **tidak boleh** menghentikan proses WO lain di batch yang sama — di-`CATCH` lokal, loop lanjut. |
| FR-04 | Tidak ada pencatatan status/tabel/log tambahan — jejak eksekusi cukup mengandalkan **job log standar SM37** (output list dari `WRITE`/pesan program) dan **SOST** untuk status pengiriman email. |
| FR-05 | Email dikirim dari sender resmi `mail_sap@unitedtractors.com` ("PT. United Tractors Tbk"), bukan default user background job, agar recipient mengenali sumber email. |
| FR-06 | Setiap pengiriman (sukses/gagal) memunculkan konfirmasi via `MESSAGE s000` di samping `WRITE` ke job log, sesuai pola existing di `SEND_EMAIL_BCS`. |

---

## 4. Spesifikasi Teknis

### 4.1 Titik Hook di `ZSVC_TRFCOST_01`

```abap
LOOP AT lt_wo INTO ls_wo.

  " ... logic existing: hitung WARDEL_BDG, set THDR-POSTING ...

  IF ls_wo-auart = 'PRT' AND thdr-posting = '1'.   " FR-01 + FR-02: filter AUART, budget minus
    PERFORM send_minus_email_pdh USING ls_wo-aufnr.
  ENDIF.

  " ... lanjut logic posting existing (POSTING_ZIPK/POSTING_ZRNT), tidak berubah ...

ENDLOOP.
```

Tidak ada FORM tambahan untuk cek/set/delete status — kondisi `thdr-posting = '1'` langsung jadi trigger kirim, tanpa syarat lain.

### 4.2 Resolusi Email PDH

Tetap pakai **SBWP Distribution List** tunggal `PDH_ALL` (objek standar SAP, bukan tabel custom) — satu-satunya cara resolve recipient tanpa bikin tabel mapping baru.

### 4.3 FORM Kirim Email — Caller (`SEND_MINUS_EMAIL_PDH`)

```abap
FORM send_minus_email_pdh USING p_aufnr TYPE aufnr.

  DATA: lt_recipients TYPE TABLE OF ty_email_recipient,
        lt_html       TYPE bcsy_text,
        ls_wo_detail  TYPE ty_wo_detail,
        lv_subject    TYPE so_obj_des.

  " Ambil detail WO untuk isi email langsung dari tabel sumber (AUFK/VBAK/dst),
  " tidak dari tabel staging
  PERFORM get_wo_detail USING p_aufnr CHANGING ls_wo_detail.

  PERFORM get_email_from_dli USING 'PDH_ALL' CHANGING lt_recipients.

  IF lt_recipients IS INITIAL.
    " Tidak ada log object -> cukup tulis ke job spool via WRITE,
    " tertangkap otomatis di job log SM37
    WRITE: / |WO { p_aufnr }: DLI PDH_ALL kosong, email tidak terkirim|.
    RETURN.
  ENDIF.

  lv_subject = 'PEMBERITAHUAN BUDGET MINUS'.

  APPEND '<html><body style="font-family:Arial,sans-serif;font-size:12px;">' TO lt_html.
  APPEND '<p>Dh ,</p>' TO lt_html.
  APPEND '<p>WO berikut belum tertransfer cost-nya karena BUDGET MINUS:</p>' TO lt_html.
  APPEND '<table border="1" cellpadding="6" style="border-collapse:collapse;">' TO lt_html.
  APPEND |<tr><td><b>No WO</b></td><td>{ ls_wo_detail-aufnr }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>Cost Center</b></td><td>{ ls_wo_detail-kostl }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>Amount</b></td><td>{ ls_wo_detail-wrbtr }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>WO Create Date</b></td><td>{ ls_wo_detail-erdat }</td></tr>| TO lt_html.
  APPEND '</table><br>' TO lt_html.
  APPEND '<p>Mohon segera dilakukan pengajuan penambahan budget melalui link berikut:<br>' &&
         '<a href="http://untr.id/f/FormSAbudgetJCSpart">Link Msflow SA Budget JCS</a></p>' TO lt_html.
  APPEND '<p>Terima kasih</p>' TO lt_html.
  APPEND '</body></html>' TO lt_html.

  TRY.
      PERFORM send_email_bcs TABLES lt_recipients      " §4.4 - reference implementation aktual
                             USING  lv_subject lt_html.
      WRITE: / |WO { p_aufnr }: email budget minus terkirim ke PDH_ALL|.
    CATCH cx_bcs INTO DATA(lx_bcs).                     " FR-03: 1 WO gagal, lanjut WO lain
      WRITE: / |WO { p_aufnr }: gagal kirim email - { lx_bcs->get_text( ) }|.
  ENDTRY.

ENDFORM.
```

### 4.4 FORM Kirim Email — `SEND_EMAIL_BCS` (Reference Implementation Aktual)

Ini adalah implementasi konkret `SEND_EMAIL_BCS` yang dipakai sebagai referensi — sudah pakai sender resmi (FR-05) dan konfirmasi via `MESSAGE s000` (FR-06), selaras dengan pola yang sama dipakai di `ZSVC_TRFCOST_02_NOTIF`.

```abap
FORM send_email_bcs TABLES  pt_email   LIKE gt_recipients
                    USING   p_subject  TYPE so_obj_des
                            p_html_tab TYPE bcsy_text
                    RAISING cx_bcs.

  CHECK NOT pt_email[] IS INITIAL.

  DATA: lv_subject         TYPE so_obj_des,
        lo_email           TYPE REF TO cl_bcs,
        lo_email_body      TYPE REF TO cl_document_bcs,
        lo_receiver        TYPE REF TO if_recipient_bcs,
        lx_exception       TYPE REF TO cx_bcs,
        lo_internet_sender TYPE REF TO if_sender_bcs,
        l_address          TYPE adr6-smtp_addr,
        lv_send_result     TYPE c.

  TRY.
* --- 1. Create email container ---
      lo_email = cl_bcs=>create_persistent( ).
      lv_subject = p_subject.

* --- 2. Create HTML document body ---
      lo_email_body = cl_document_bcs=>create_document(
                                          i_type = 'HTM'
                                          i_text = p_html_tab
                                          i_subject = lv_subject ).

      lo_email->set_document( lo_email_body ).

* --- 3. Set sender resmi (FR-05): mail_sap@unitedtractors.com ---
      lo_internet_sender = cl_cam_address_bcs=>create_internet_address(
                                              i_address_string = 'mail_sap@unitedtractors.com'
                                              i_address_name   = 'PT. United Tractors Tbk' ).
      CALL METHOD lo_email->set_sender
        EXPORTING
          i_sender = lo_internet_sender.

* --- 4. Add recipients ---
      LOOP AT pt_email.
        l_address = pt_email-recipient.
        lo_receiver = cl_cam_address_bcs=>create_internet_address( l_address ).
        lo_email->add_recipient( i_recipient = lo_receiver
                                 i_express = 'X' ).
      ENDLOOP.

* --- 5. Send immediately (bypass SOST queue) ---
      lo_email->set_send_immediately( 'X' ).

      lo_email->send( EXPORTING
                          i_with_error_screen = 'X'
                      RECEIVING
                          result = lv_send_result ).

* --- 6. Konfirmasi status kirim (FR-06) ---
      IF lv_send_result = 'X'.
        MESSAGE s000(db) WITH 'Email has been sent'.
      ENDIF.

      COMMIT WORK.

    CATCH cx_bcs INTO lx_exception.
      MESSAGE s000(db) WITH 'Email has not been sent'.
      RAISE EXCEPTION lx_exception.
  ENDTRY.

ENDFORM.                    " SEND_EMAIL_BCS
```

**Catatan implementasi:**
- `pt_email LIKE gt_recipients` — parameter TABLES mengikuti tipe global `gt_recipients` yang sudah didefinisikan di level program (pola sama seperti di `ZSVC_TRFCOST_02_NOTIF`). Pastikan `ZSVC_TRFCOST_01` juga punya deklarasi `gt_recipients TYPE tt_email_recipient` di global data sebelum FORM ini dipanggil.
- `RAISING cx_bcs` — exception di-raise ulang ke caller (`SEND_MINUS_EMAIL_PDH`), yang menangkapnya via `CATCH cx_bcs` (FR-03) supaya kegagalan 1 WO tidak menghentikan loop.
- `MESSAGE s000(db)` bersifat tambahan di atas `WRITE` yang sudah ada di caller — keduanya boleh jalan bersamaan, tidak saling menggantikan; `WRITE` tetap yang jadi sumber utama jejak per-WO di job log (FR-04), `MESSAGE` sekadar konfirmasi status kirim/gagal generik dari sisi FM ini sendiri.
- `i_express = 'X'` pada `add_recipient` menandai semua penerima sebagai express recipient (bukan cc/bcc) — sesuai kebutuhan notifikasi langsung ke PDH.

### 4.5 Types Pendukung

```abap
TYPES: BEGIN OF ty_wo_detail,
         aufnr TYPE aufnr,
         kostl TYPE kostl,
         erdat TYPE erdat,
         wrbtr TYPE wrbtr,
       END OF ty_wo_detail.

TYPES: BEGIN OF ty_email_recipient,
         recipient TYPE ad_smtpadr,
         name      TYPE so_obj_des,
       END OF ty_email_recipient.
TYPES: tt_email_recipient TYPE STANDARD TABLE OF ty_email_recipient
                          WITH NON-UNIQUE DEFAULT KEY.

DATA: gt_recipients TYPE tt_email_recipient.   " dipakai sebagai LIKE reference di §4.4
```

---

## 5. Jejak Eksekusi Tanpa SLG1

- **Job log SM37**: setiap `WRITE` di §4.3 otomatis masuk ke output list job, terlihat lewat `SM37 → Job log/Spool`. Ini cukup untuk troubleshooting harian tanpa perlu SLG1.
- **`MESSAGE s000(db)`** di §4.4: konfirmasi tambahan level FM, muncul di layar/spool job juga (karena background job non-interaktif, message class `s`/success tetap tercatat di job log, bukan pop-up).
- **SOST**: status pengiriman tiap email (delivered/error) tetap bisa dicek standar di sana — `CL_BCS` selalu mendaftarkan send request ke SOST terlepas dari ada/tidaknya SLG1.

---

## 6. Trade-off vs Desain dengan User Status/SLG1

| Kriteria | Desain ini (paling minimal) | Desain sebelumnya (user status + SLG1) |
|---|---|---|
| Object baru | **Nol** — tidak ada tabel, status profile, atau log object | Perlu setup Status Profile + User Status (`ZNOT`) |
| Effort development | Paling ringan — 1 FORM caller + 1 FORM sender (reference implementation) | Lebih berat — 4 FORM + config |
| **Email duplikat** | **Ya, akan berulang** setiap kali job jalan selama WO masih minus (tidak ada dedup) | Tidak — status `ZNOT` mencegah kirim ulang |
| Audit trail terstruktur | Tidak ada — hanya job log SM37 (biasanya di-purge otomatis setelah beberapa hari/minggu sesuai retention) | Ada — histori status `JCDS` |
| Traceability jangka panjang | Rendah — begitu job log SM37 di-purge, riwayat hilang | Lebih baik, meski masih tidak sekuat tabel dedicated |
| Risiko "spam" ke PDH | **Tinggi** kalau job `ZSVC_TRFCOST_01` jalan lebih dari 1x sehari, atau WO minus berlarut-larut berhari-hari — PDH bisa terima email yang sama berulang setiap run | Rendah, terkontrol |
| Sender identity | Sudah resmi (`mail_sap@unitedtractors.com`) — sama di kedua desain | Sama |
| Cocok untuk | Kebutuhan sesaat/sederhana, job jalan jarang (mis. 1x/hari), volume WO PRT minus kecil | Kebutuhan produksi jangka panjang dengan volume lebih besar |

> **Catatan penting:** karena tidak ada mekanisme dedup sama sekali, **frekuensi kirim email = frekuensi job `ZSVC_TRFCOST_01` dijalankan**. Kalau job ini jalan beberapa kali sehari (perlu dikonfirmasi jadwal aktualnya), PDH akan menerima email berulang untuk WO yang sama selama budget belum ditambah. Ini murni konsekuensi dari keputusan "tanpa status, tanpa log" — bukan bug.

---

## 7. Pertanyaan Terbuka / Asumsi

| # | Item | Asumsi | Perlu Dikonfirmasi |
|---|---|---|---|
| OQ-1 | Frekuensi job `ZSVC_TRFCOST_01` | Diasumsikan 1x/hari — kalau lebih sering, email berulang ke PDH bisa dianggap mengganggu. | Confirm jadwal SM36 job existing. |
| OQ-2 | Toleransi terhadap email berulang | Diasumsikan business menerima risiko ini demi kesederhanaan. | Confirm ke PDH/business apakah repetisi harian/lebih sering ini masih acceptable. |
| OQ-3 | Retention job log SM37 | Diasumsikan retention default sistem (biasanya beberapa minggu) cukup untuk troubleshooting jangka pendek. | Confirm kebijakan job log cleanup di Basis. |
| OQ-4 | Definisi "PDH" sebagai recipient tunggal | Satu DLI global `PDH_ALL`. | Confirm apakah perlu dipisah per cost center/plant (lihat juga PRD terpisah untuk varian per-WERKS/HO+Cabang). |
| OQ-5 | **Baru** — Konsistensi `gt_recipients` sebagai global data | Diasumsikan `ZSVC_TRFCOST_01` akan menambahkan deklarasi global `gt_recipients` baru (§4.5) khusus untuk fitur ini, tidak bentrok dengan variabel existing di program. | Confirm tidak ada naming collision dengan data existing di `ZSVC_TRFCOST_01`. |

---

## 8. Acceptance Criteria

- [ ] WO dengan `AUART = 'PRT'` dan `SALDO < 0` → email terkirim ke `PDH_ALL` saat job berjalan.
- [ ] WO dengan `AUART` selain `PRT` → tidak ada email sama sekali.
- [ ] Kegagalan kirim email untuk 1 WO tidak menghentikan proses WO lain di batch yang sama.
- [ ] Tidak ada Z-table, User Status/Status Profile baru, maupun entry SLG1 yang dibuat oleh perubahan ini.
- [ ] Job log SM37 menampilkan baris untuk setiap WO yang diproses (terkirim/gagal/DLI kosong), plus `MESSAGE s000` dari `SEND_EMAIL_BCS`.
- [ ] Email yang diterima PDH menunjukkan sender `mail_sap@unitedtractors.com` / "PT. United Tractors Tbk", bukan default user background job.
- [ ] SOST menunjukkan send request untuk setiap email yang terkirim.
