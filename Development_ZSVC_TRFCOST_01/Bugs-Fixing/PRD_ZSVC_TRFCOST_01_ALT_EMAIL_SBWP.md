# PRD (Alternatif) — ZSVC_TRFCOST_01: Direct Email Notification Budget Minus ke HO + Cabang (WERKS), Tanpa Z-Table, Tanpa User Status, Tanpa SLG1

| | |
|---|---|
| **Program** | `ZSVC_TRFCOST_01` (Report existing — JCS Cost Transfer / Reman Service) |
| **Pemilik** | SVC / Cost Control (IT/IS) |
| **Status** | Draft untuk Review — Rev. 4 (recipient jadi union HO + Cabang, sesuai struktur folder SBWP aktual) |
| **Relasi ke PRD Lain** | Alternatif dari `PRD_ZSVC_TRFCOST_01_ID.md` (staging table) dan versi sebelumnya dari dokumen ini (Rev. 1-3: user status, lalu 1 DLI tunggal `PDH_ALL`). Dokumen ini **menggantikan resolusi recipient** dengan union HO + Cabang, konsisten dengan `PRD_ZSVC_TRFCOST_01_BUDGET_MINUS_FINAL_ID.md`. |

---

## 1. Ringkasan Eksekutif

Desain ini tetap **minimal**: tidak ada Z-table, tidak ada setup User Status/Status Profile baru, dan tidak ada application log SLG1. Program `ZSVC_TRFCOST_01` hanya ditambah **satu titik hook** — begitu budget-check menghasilkan `SALDO < 0` untuk WO dengan `AUART = 'PRT'`, email langsung dikirim.

**Yang berubah di Rev. 4:** recipient **bukan lagi 1 DLI tunggal** (`PDH_ALL`), melainkan **union dari dua folder SBWP**, sesuai struktur folder yang sudah dibuat Admin (lihat §2, View aktual):

```
TRFCOST_01 : Budget Minus - ZSVC_TRFCOST_01
 ├── BPDH_HO   : Budget Minus - Admin HO        (selalu dikirim, semua WO)
 ├── BPDH_JKT  : BudgetMin_PDH_JKT               (khusus WO plant JKT)
 └── BPDH_JYP  : BudgetMin_PDH_JYP               (khusus WO plant JYP)
```

Setiap WO Budget Minus dikirim ke **`BPDH_HO` + `BPDH_<WERKS>` sesuai plant WO tersebut** (union, dedupe) — bukan ke satu folder generik. Tidak ada perubahan pada bagian lain: tetap tanpa dedup status, tetap tanpa SLG1, jejak tetap lewat job log (`WRITE`) dan `MESSAGE s000` di `SEND_EMAIL_BCS`.

---

## 2. Struktur Folder SBWP (View Aktual)

Screenshot struktur folder yang sudah dibuat Admin di SBWP:

```
TRFCOST_01 : Budget Minus - ZSVC_TRFCOST_01
 ├── BPDH_HO   : Budget Minus - Admin HO
 ├── BPDH_JKT  : BudgetMin_PDH_JKT
 └── BPDH_JYP  : BudgetMin_PDH_JYP
```

| Folder | Cakupan | Selalu dikirim? |
|---|---|---|
| `BPDH_HO` | Admin HO — harus tahu **semua** kasus Budget Minus di semua plant | **Ya**, tanpa syarat |
| `BPDH_<WERKS>` (mis. `BPDH_JKT`, `BPDH_JYP`) | PDH cabang — hanya WO dari plant tersebut | Hanya jika `WERKS` WO cocok **dan** foldernya ada |

**Penamaan folder cabang:** `BPDH_<WERKS>`, `<WERKS>` dibentuk otomatis dari field `WERKS` WO. Folder baru untuk plant lain (di luar JKT/JYP) dibuat manual oleh Admin dengan pola nama yang sama — program tidak perlu diubah lagi untuk plant baru, tinggal folder-nya dibuat.

---

## 2.1 Prasyarat: Field `WERKS` di Internal Table WO

Karena resolusi recipient sekarang butuh `WERKS` per WO, pastikan field ini tersedia saat hook dipanggil. Jika `ls_wo` (internal table WO di `ZSVC_TRFCOST_01`) belum membawa `WERKS`, tambahkan pengambilan singkat sebelum hook:

```abap
DATA lv_werks TYPE werks_d.

SELECT SINGLE werks FROM aufk INTO lv_werks
  WHERE aufnr = ls_wo-aufnr.
```

atau langsung tambahkan `WERKS` ke `SELECT`/struktur `ls_wo` existing kalau field itu sudah bisa didapat dari situ (lebih efisien, hindari `SELECT SINGLE` tambahan di dalam loop).

---

## 3. Scope

### 3.1 Di Dalam Scope
- Hook di budget-check block existing `ZSVC_TRFCOST_01` — tetap **tidak ada tabel baru, tidak ada status baru, tidak ada log object baru**.
- Filter: hanya WO dengan `AUART = 'PRT'`.
- Recipient = **union** `BPDH_HO` + `BPDH_<WERKS>` (jika ada), dedupe case-insensitive.
- Kirim email setiap kali job mendeteksi `SALDO < 0` untuk WO tersebut (bisa berulang di run berikutnya selama masih minus — lihat §7 Trade-off, tidak berubah dari Rev. 3).

### 3.2 Di Luar Scope
- Tidak ada dedup/anti-spam mechanism (tidak ada tabel maupun status untuk melacak "sudah dinotif").
- Tidak ada audit trail/histori tersimpan di sistem (selain job log standar SM37 bawaan background job).
- Tidak ada digest/rekap — 1 email per WO per kejadian terdeteksi, dikirim ke gabungan HO+Cabang.
- Tidak mengubah logika budget calculation maupun approval gate existing.
- Tidak membangun automasi pembuatan folder plant baru (tetap manual oleh Admin).

---

## 4. Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | Saat `ZSVC_TRFCOST_01` mendeteksi `SALDO < 0` untuk WO `AUART = 'PRT'`, sistem mengirim email **pada saat itu juga**. |
| FR-02 | WO dengan `AUART` selain `PRT` tidak diproses sama sekali. |
| FR-03 | Kegagalan kirim email untuk 1 WO (`cx_bcs`) tidak boleh menghentikan proses WO lain di batch yang sama. |
| FR-04 | Jejak eksekusi cukup lewat **job log SM37** (`WRITE`) dan **SOST** — tidak ada SLG1. |
| FR-05 | Email dikirim dari sender resmi `mail_sap@unitedtractors.com` ("PT. United Tractors Tbk"). |
| FR-06 | Setiap pengiriman (sukses/gagal) memunculkan konfirmasi via `MESSAGE s000`, selain `WRITE` ke job log. |
| FR-07 | **Baru** — Recipient = folder `BPDH_HO` **selalu** diikutkan, **ditambah** folder `BPDH_<WERKS>` sesuai `WERKS` WO tersebut, jika foldernya ada. |
| FR-08 | **Baru** — Alamat yang muncul di kedua folder (HO dan cabang) hanya menerima **1 email** (dedupe case-insensitive). |
| FR-09 | **Baru** — Jika folder `BPDH_<WERKS>` untuk plant WO tersebut **tidak ditemukan**, email tetap terkirim ke `BPDH_HO` saja; job **tidak fail**, tercatat di job log "DLI cabang tidak ditemukan untuk Werks {WERKS}". |

---

## 5. Spesifikasi Teknis

### 5.1 Titik Hook di `ZSVC_TRFCOST_01`

```abap
LOOP AT lt_wo INTO ls_wo.

  " ... logic existing: hitung WARDEL_BDG, set THDR-POSTING ...

  IF ls_wo-auart = 'PRT' AND thdr-posting = '1'.   " FR-01 + FR-02: filter AUART, budget minus
    PERFORM send_minus_email_pdh USING ls_wo-aufnr
                                        ls_wo-werks.        " FR-07: WERKS dibawa masuk
  ENDIF.

  " ... lanjut logic posting existing (POSTING_ZIPK/POSTING_ZRNT), tidak berubah ...

ENDLOOP.
```

### 5.2 FORM Kirim Email — Caller (`SEND_MINUS_EMAIL_PDH`)

```abap
FORM send_minus_email_pdh USING p_aufnr TYPE aufnr
                                 p_werks TYPE werks_d.

  DATA: lt_recipients TYPE tt_email_recipient,
        lt_html       TYPE bcsy_text,
        ls_wo_detail  TYPE ty_wo_detail,
        lv_subject    TYPE so_obj_des.

  PERFORM get_wo_detail USING p_aufnr CHANGING ls_wo_detail.

  " Union HO + Cabang, dedupe, sesuai folder BPDH_HO / BPDH_<WERKS> (§5.3)
  PERFORM get_minus_recipients USING p_werks
                                CHANGING lt_recipients.

  IF lt_recipients IS INITIAL.
    " Kasus ekstrem: BPDH_HO sendiri kosong/tidak terbaca
    WRITE: / |WO { p_aufnr } (Plant { p_werks }): tidak ada recipient valid (BPDH_HO kosong) - email tidak terkirim|.
    RETURN.
  ENDIF.

  lv_subject = 'PEMBERITAHUAN BUDGET MINUS'.

  APPEND '<html><body style="font-family:Arial,sans-serif;font-size:12px;">' TO lt_html.
  APPEND '<p>Dh ,</p>' TO lt_html.
  APPEND '<p>WO berikut belum tertransfer cost-nya karena BUDGET MINUS:</p>' TO lt_html.
  APPEND '<table border="1" cellpadding="6" style="border-collapse:collapse;">' TO lt_html.
  APPEND |<tr><td><b>No WO</b></td><td>{ ls_wo_detail-aufnr }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>Plant</b></td><td>{ p_werks }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>Cost Center</b></td><td>{ ls_wo_detail-kostl }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>Amount</b></td><td>{ ls_wo_detail-wrbtr }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>WO Create Date</b></td><td>{ ls_wo_detail-erdat }</td></tr>| TO lt_html.
  APPEND '</table><br>' TO lt_html.
  APPEND '<p>Mohon segera dilakukan pengajuan penambahan budget melalui link berikut:<br>' &&
         '<a href="http://untr.id/f/FormSAbudgetJCSpart">Link Msflow SA Budget JCS</a></p>' TO lt_html.
  APPEND '<p>Terima kasih</p>' TO lt_html.
  APPEND '</body></html>' TO lt_html.

  TRY.
      PERFORM send_email_bcs TABLES lt_recipients      " §5.5 - reference implementation aktual
                             USING  lv_subject lt_html.
      WRITE: / |WO { p_aufnr } (Plant { p_werks }): email terkirim ke { lines( lt_recipients ) } recipient (HO+Cabang)|.
    CATCH cx_bcs INTO DATA(lx_bcs).                     " FR-03: 1 WO gagal, lanjut WO lain
      WRITE: / |WO { p_aufnr } (Plant { p_werks }): gagal kirim email - { lx_bcs->get_text( ) }|.
  ENDTRY.

ENDFORM.
```

### 5.3 FORM Resolusi Union HO + Cabang (Baru — Menggantikan `GET_EMAIL_FROM_DLI` Tunggal)

```abap
FORM get_minus_recipients USING p_werks TYPE werks_d
                           CHANGING p_recipients TYPE tt_email_recipient.

  DATA: lt_ho         TYPE tt_email_recipient,
        lt_cabang     TYPE tt_email_recipient,
        lv_folder_cbg TYPE so_obj_nam.

  " 1. Folder HO - SELALU dibaca (FR-07)
  PERFORM get_email_from_dli USING 'BPDH_HO' CHANGING lt_ho.

  IF lt_ho IS INITIAL.
    WRITE: / |BPDH_HO kosong atau tidak ditemukan - cek setup folder SBWP|.
  ENDIF.

  " 2. Bentuk nama folder cabang otomatis dari WERKS
  lv_folder_cbg = |BPDH_{ p_werks }|.
  CONDENSE lv_folder_cbg.

  " 3. Baca folder cabang - kalau tidak ada, lt_cabang tetap kosong (bukan error, FR-09)
  PERFORM get_email_from_dli USING lv_folder_cbg CHANGING lt_cabang.

  IF lt_cabang IS INITIAL.
    WRITE: / |WERKS { p_werks }: DLI cabang { lv_folder_cbg } tidak ditemukan - notifikasi hanya ke BPDH_HO|.
  ENDIF.

  " 4. Union
  p_recipients = lt_ho.
  APPEND LINES OF lt_cabang TO p_recipients.

  " 5. Dedupe case-insensitive (FR-08)
  PERFORM dedupe_recipients CHANGING p_recipients.

ENDFORM.

FORM dedupe_recipients CHANGING p_recipients TYPE tt_email_recipient.

  LOOP AT p_recipients ASSIGNING FIELD-SYMBOL(<ls_rec>).
    <ls_rec>-recipient = to_upper( <ls_rec>-recipient ).
  ENDLOOP.

  SORT p_recipients BY recipient.
  DELETE ADJACENT DUPLICATES FROM p_recipients COMPARING recipient.

ENDFORM.
```

### 5.4 FORM Baca Isi Folder SBWP (`GET_EMAIL_FROM_DLI` — Reuse, Nama Parameter Fleksibel)

```abap
FORM get_email_from_dli USING    p_dli_name TYPE soobjinfi1-obj_name
                         CHANGING ct_recipients TYPE tt_email_recipient.

  DATA: dli_entries          LIKE sodlienti1 OCCURS 0 WITH HEADER LINE,
        ls_recipient         TYPE ty_email_recipient,
        lv_dli_name_internal LIKE soobjinfi1-obj_name.

  CLEAR ct_recipients.
  lv_dli_name_internal = p_dli_name.

* --- Try SHARED folder first ---
  CALL FUNCTION 'SO_DLI_READ_API1'
    EXPORTING
      dli_name                   = lv_dli_name_internal
      shared_dli                 = 'X'
    TABLES
      dli_entries                = dli_entries
    EXCEPTIONS
      dli_not_exist              = 1
      operation_no_authorization = 2
      parameter_error            = 3
      x_error                    = 4
      OTHERS                     = 5.

* --- Fallback ke personal folder ---
  IF sy-subrc <> 0.
    REFRESH dli_entries.
    CALL FUNCTION 'SO_DLI_READ_API1'
      EXPORTING
        dli_name                   = lv_dli_name_internal
        shared_dli                 = ' '
      TABLES
        dli_entries                = dli_entries
      EXCEPTIONS
        dli_not_exist              = 1
        operation_no_authorization = 2
        parameter_error            = 3
        x_error                    = 4
        OTHERS                     = 5.
  ENDIF.

  IF sy-subrc <> 0.
    RETURN.   " folder tidak ditemukan -> kosong, ditangani caller (bukan error)
  ENDIF.

  LOOP AT dli_entries.
    IF dli_entries-member_adr IS NOT INITIAL.
      CLEAR ls_recipient.
      ls_recipient-recipient = dli_entries-member_adr.
      ls_recipient-name      = dli_entries-member_nam.
      APPEND ls_recipient TO ct_recipients.
    ENDIF.
  ENDLOOP.

ENDFORM.
```

> **Catatan:** kode ini konsisten dengan `GET_EMAIL_FROM_DLI` yang sudah dipakai di `ZSVC_TRFCOST_02_NOTIF` (`FORM GET_EMAIL_FROM_DLI`) — dipanggil dua kali (untuk `BPDH_HO` dan `BPDH_<WERKS>`) alih-alih sekali untuk `PDH_ALL` seperti di Rev. 3.

### 5.5 FORM Kirim Email — `SEND_EMAIL_BCS` (Reference Implementation Aktual — Tidak Berubah dari Rev. 3)

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

### 5.6 Types Pendukung

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

DATA: gt_recipients TYPE tt_email_recipient.   " dipakai sebagai LIKE reference di §5.5
```

---

## 6. Jejak Eksekusi Tanpa SLG1

- **Job log SM37**: setiap `WRITE` di §5.2/§5.3 otomatis masuk ke output list job (`SM37 → Job log/Spool`), termasuk pesan "DLI cabang tidak ditemukan untuk Werks {WERKS}" (FR-09).
- **`MESSAGE s000(db)`** di §5.5: konfirmasi tambahan level FM.
- **SOST**: status pengiriman tiap email tetap bisa dicek standar di sana.

---

## 7. Trade-off vs Desain dengan User Status/SLG1

| Kriteria | Desain ini (minimal, HO+Cabang) | Desain sebelumnya (user status + SLG1) |
|---|---|---|
| Object baru | **Nol** — hanya konsumsi folder SBWP existing (`BPDH_HO`, `BPDH_<WERKS>`) | Perlu setup Status Profile + User Status (`ZNOT`) |
| Effort development | Ringan — 2 FORM baru (caller + resolusi union) + reuse `GET_EMAIL_FROM_DLI`/`SEND_EMAIL_BCS` | Lebih berat — 4 FORM + config |
| **Email duplikat** | **Ya, akan berulang** setiap kali job jalan selama WO masih minus (tidak ada dedup di level WO) | Tidak — status `ZNOT` mencegah kirim ulang |
| Cakupan recipient | Lebih lengkap dari Rev. 3 — HO **selalu** dapat + cabang sesuai plant | Sama, tapi lewat status bukan folder |
| Audit trail terstruktur | Tidak ada — hanya job log SM37 | Ada — histori status `JCDS` |
| Risiko "spam" ke PDH/HO | **Tinggi** kalau job jalan lebih dari 1x sehari, atau WO minus berlarut-larut | Rendah, terkontrol |
| Cocok untuk | Kebutuhan HO+Cabang tanpa dedup canggih, job jalan jarang (mis. 1x/hari) | Kebutuhan produksi jangka panjang dengan volume lebih besar |

> **Catatan penting (tidak berubah):** karena tidak ada mekanisme dedup, **frekuensi kirim email = frekuensi job `ZSVC_TRFCOST_01` dijalankan**. Sekarang volume email berpotensi **lebih tinggi** dibanding Rev. 3, karena setiap kejadian mengirim ke minimal 2 folder (HO + Cabang) sekaligus, bukan 1 folder generik.

---

## 8. Pertanyaan Terbuka / Asumsi

| # | Item | Asumsi | Perlu Dikonfirmasi |
|---|---|---|---|
| OQ-1 | Frekuensi job `ZSVC_TRFCOST_01` | Diasumsikan 1x/hari. | Confirm jadwal SM36 job existing. |
| OQ-2 | Toleransi terhadap email berulang | Diasumsikan business menerima risiko ini demi kesederhanaan. | Confirm ke HO/PDH apakah repetisi masih acceptable. |
| OQ-3 | Retention job log SM37 | Diasumsikan retention default cukup untuk troubleshooting jangka pendek. | Confirm kebijakan job log cleanup di Basis. |
| OQ-4 | Ketersediaan field `WERKS` di internal table WO | Diasumsikan perlu tambahan `SELECT`/field carry (§2.1) jika belum ada. | Cek struktur `ls_wo` aktual di program. |
| OQ-5 | Konsistensi `gt_recipients` sebagai global data | Diasumsikan deklarasi baru, tidak bentrok dengan variabel existing. | Confirm tidak ada naming collision di `ZSVC_TRFCOST_01`. |
| OQ-6 | **Baru** — Plant di luar `JKT`/`JYP` belum punya folder `BPDH_<WERKS>` | Program tetap kirim ke `BPDH_HO` saja untuk plant yang belum punya folder (FR-09), sesuai desain fallback. | Pastikan daftar plant mana saja yang perlu folder sebelum go-live, supaya cabang tidak lama tidak dapat notifikasi. |

---

## 9. Acceptance Criteria

- [ ] WO `AUART = 'PRT'`, `SALDO < 0`, plant `JKT` → email terkirim ke seluruh member `BPDH_HO` **dan** seluruh member `BPDH_JKT`.
- [ ] Alamat yang sama di kedua folder hanya menerima **1 email** (dedupe case-insensitive terverifikasi).
- [ ] WO plant yang **belum** punya folder cabang → email tetap terkirim ke `BPDH_HO` saja, job log mencatat pesan fallback, job **tidak fail**.
- [ ] WO dengan `AUART` selain `PRT` → tidak ada email sama sekali.
- [ ] Kegagalan kirim email untuk 1 WO tidak menghentikan proses WO lain di batch yang sama.
- [ ] Tidak ada Z-table, User Status/Status Profile baru, maupun entry SLG1 yang dibuat.
- [ ] Job log SM37 menampilkan baris untuk setiap WO yang diproses (terkirim/gagal/fallback HO-only), plus `MESSAGE s000` dari `SEND_EMAIL_BCS`.
- [ ] Email yang diterima menunjukkan sender `mail_sap@unitedtractors.com` / "PT. United Tractors Tbk".
- [ ] SOST menunjukkan send request untuk setiap email yang terkirim.
