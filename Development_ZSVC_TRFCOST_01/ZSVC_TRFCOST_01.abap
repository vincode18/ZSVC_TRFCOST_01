*&---------------------------------------------------------------------*
*& Report  ZSVC_TRFCOST                                                *
*&                                                                     *
*&---------------------------------------------------------------------*
*& MODIF by VTR 26.04.2016 IT/IS 2413                                  *
*& Tambah filter untuk Automatic Transfer Cost :                       *
*& - TECO Date,                                                        *
*& - GL Account & Order Reason & Allocation,                           *
*& - PJB Date                                                          *
*&---------------------------------------------------------------------*

REPORT  zsvc_trfcost  NO STANDARD PAGE HEADING LINE-SIZE 170.
DATA: xkostl    LIKE cobl-kostl,
      ccd_txt   LIKE kna1-name1,
      ccdet(50),
      tmess(50).
DATA: no      LIKE sy-tabix,
      tno(6), tbrs(6),
      txt     LIKE sy-msgv1.
DATA: v_ucomm LIKE sy-ucomm.
INCLUDE zalv_variable.
RANGES: r_aufart FOR aufk-auart.
DATA: v_auart(250).
TABLES: aufk, caufv, caufvd, vbak, vbap, vbep, zaugru, zsnmodel, equi, zusernr.
TABLES: tvauk, viaufks, "cosp,
        csks, zsvctdtl.
DATA:  colpos LIKE fieldcat_ln-col_pos.

DATA: BEGIN OF erlist OCCURS 0,
        ecode(1)   TYPE c,
        ertxt(132) TYPE c,
        aufnr      LIKE aufk-aufnr,
        sgtxt(50)  TYPE c,
      END OF erlist.
* Batchinputdata of single transaction
DATA: BEGIN OF bdcdata OCCURS 0.
        INCLUDE STRUCTURE bdcdata.
DATA: END OF bdcdata.

DATA BEGIN OF messtab OCCURS 10.
INCLUDE STRUCTURE bdcmsgcoll.
DATA END OF messtab.
* End of Batchinputdata

DATA: hcaufv LIKE caufv OCCURS   0 WITH HEADER LINE,
*      IEBCSD LIKE EBCSD OCCURS   0 WITH HEADER LINE,
      hpmco  LIKE pmco OCCURS    0 WITH HEADER LINE,
      iacpos LIKE tpir1t OCCURS  0 WITH HEADER LINE,
      itvauk LIKE tvauk OCCURS   0 WITH HEADER LINE,
      iaugru LIKE zaugru OCCURS   0 WITH HEADER LINE.

DATA: i003o LIKE t003o OCCURS   0 WITH HEADER LINE.

DATA: BEGIN OF iaufk OCCURS 0.
        INCLUDE STRUCTURE viaufks.
DATA:   acost    LIKE pmco-wrt00,
        sttxt    LIKE caufvd-sttxt,
        error(1),
        trans(1),
        delet(1).
DATA: END OF iaufk.
DATA: BEGIN OF xaufk OCCURS   0,
        aufnr LIKE aufk-aufnr,
      END OF xaufk.

DATA: aufk_upd LIKE aufk OCCURS   0 WITH HEADER LINE.

DATA: BEGIN OF ilagp OCCURS   0,
        lgpla LIKE lagp-lgpla,
      END OF ilagp.

DATA: BEGIN OF xlagp OCCURS   0,
        lgnum LIKE lagp-lgnum,
        lgtyp LIKE lagp-lgtyp,
        lgpla LIKE lagp-lgpla,
      END OF xlagp.

DATA: BEGIN OF ibkpf OCCURS   0,
        aufnr  LIKE caufv-aufnr,
        auart  LIKE caufv-auart,
        bukrs  LIKE caufv-bukrs,
        gsber  LIKE caufv-gsber,
        waers  LIKE caufv-waers,
        maufnr LIKE caufv-maufnr,
        mauart LIKE caufv-auart,
        objnr  LIKE caufv-objnr,
        blart  LIKE bkpf-blart,
        bldat  LIKE bkpf-bldat,
        budat  LIKE bkpf-budat,
        monat  LIKE bkpf-monat,
        bktxt  LIKE bkpf-bktxt,
      END OF ibkpf.

DATA: BEGIN OF ibseg OCCURS   0,
        aufnr LIKE caufv-aufnr,
        objnr LIKE caufv-objnr,
        item  LIKE sy-tabix,
        newbs LIKE rf05a-newbs,
        newko LIKE rf05a-newko,
        bukrs LIKE bseg-bukrs,
        belnr LIKE bseg-belnr,
        gjahr LIKE bseg-gjahr,
        buzei LIKE bseg-buzei,
        gsber LIKE bseg-gsber,
        wrbtr LIKE bseg-wrbtr,
        zuonr LIKE bseg-zuonr,
        sgtxt LIKE bseg-sgtxt,
        pernr LIKE bseg-pernr,
      END OF ibseg.

DATA: BEGIN OF thdr OCCURS   0,
        indictr(4) TYPE c,
        posting(1) TYPE c,    "0 = boleh posting --- 1 = gak boleh
        bdgtxt(15) TYPE c,
        saltxt(15) TYPE c,
        budget     TYPE v_cosp_view-wog001,
        actual     TYPE v_cosp_view-wog001,
        saldo      TYPE v_cosp_view-wog001,
        aufnr      LIKE caufv-aufnr,
        werks      LIKE caufv-werks,
        seque      LIKE sy-tabix,
        auart      LIKE caufv-auart,
        bukrs      LIKE bkpf-bukrs,
        blart      LIKE bkpf-blart,
        budat      LIKE bkpf-budat,
        bldat      LIKE bkpf-bldat,
        monat      LIKE bkpf-monat,
        xblnr      LIKE bkpf-xblnr,
        bktxt      LIKE bkpf-bktxt,
        waers      LIKE bkpf-waers,
        vspart     LIKE vbak-spart,
        vaugru     LIKE vbak-augru,
        vaugru_d   LIKE vbak-augru,
        uspart     LIKE vbak-spart,
        ubstzd     LIKE vbak-bstzd,
        vkunnr     LIKE vbak-kunnr,
      END OF thdr.

DATA: BEGIN OF tdtl OCCURS   0,
        aufnr LIKE caufv-aufnr,
        seque LIKE sy-tabix,
        item  LIKE sy-tabix,
        newbs LIKE rf05a-newbs,
        newko LIKE rf05a-newko,
        gsber LIKE bseg-gsber,
        wrbtr LIKE bseg-wrbtr,
        waers LIKE bkpf-waers,
        zuonr LIKE bseg-zuonr,
        sgtxt LIKE bseg-sgtxt,
        kostl LIKE bseg-kostl,
        order LIKE bseg-aufnr,
        acpos LIKE pmco-acpos,
        kdauf LIKE aufk-kdauf,
        kdpos LIKE aufk-kdpos,
      END OF tdtl.

DATA: BEGIN OF hdr OCCURS   0,
        aufnr    LIKE caufv-aufnr,
        auart    LIKE caufv-auart,
        bukrs    LIKE caufv-bukrs,
        gsber    LIKE caufv-gsber,
        werks    LIKE caufv-werks,
        waers    LIKE caufv-waers,
        objnr    LIKE caufv-objnr,
        kdauf    LIKE caufv-kdauf,
        kdpos    LIKE caufv-kdpos,
        ingpr    LIKE caufvd-ingpr,
        ilart    LIKE caufvd-ilart,
*       Superior Order
        maufnr   LIKE caufv-maufnr,
        mauart   LIKE caufv-auart,
        mwerks   LIKE caufv-werks,
        mgsber   LIKE caufv-gsber,
*       Leading Order
        laufnr   LIKE caufv-aufnr,
        lauart   LIKE caufv-auart,
        lwerks   LIKE caufv-werks,
        lgsber   LIKE caufv-gsber,
*       Target Order
        taufnr   LIKE caufv-aufnr,
        tauart   LIKE caufv-auart,
        twerks   LIKE caufv-werks,
        tgsber   LIKE caufv-gsber,
*       Sales Order
        vauart   LIKE vbak-auart,
        vaugru   LIKE vbak-augru,
        vaugru_d LIKE vbak-augru,
        vvkorg   LIKE vbak-vkorg,
        vvtweg   LIKE vbak-vtweg,
        vspart   LIKE vbak-spart,
        vkostl   LIKE tvauk-kostl,
        vgskst   LIKE tvauk-gskst,
        vvkbur   LIKE vbak-vkbur,
        vabrvw   LIKE vbak-abrvw,
        vkunnr   LIKE vbak-kunnr,
        vvgbel   LIKE vbak-vgbel,
        vmatnr   LIKE vbap-matnr,
        vpstyv   LIKE vbap-pstyv,
        vwerks   LIKE vbap-werks,
        vuepos   LIKE vbap-uepos,
        vvgpos   LIKE vbap-vgpos,
        uspart   LIKE vbak-spart,
        uauart   LIKE vbak-auart,
        uaugru   LIKE vbak-augru,
        ubstzd   LIKE vbak-bstzd,
        ukostl   LIKE tvauk-kostl,
        ugskst   LIKE tvauk-gskst,
        akunnr   LIKE vbak-kunnr,
        azuonr   LIKE bseg-zuonr,
        ahkont   LIKE bseg-hkont,
        gsbe1    LIKE caufv-gsber,
        newd1    LIKE rf05a-newko,
        newc1    LIKE rf05a-newko,
        gsbe2    LIKE caufv-gsber,
        newd2    LIKE rf05a-newko,
        newc2    LIKE rf05a-newko,
        gsbe3    LIKE caufv-gsber,
        newd3    LIKE rf05a-newko,
        newc3    LIKE rf05a-newko,
        delet(1),
        flag(1),
      END OF hdr.

DATA: zhdr      LIKE thdr OCCURS 0 WITH HEADER LINE.
DATA: itab_cosp TYPE v_cosp_view OCCURS 0 WITH HEADER LINE.
DATA: itab_bsis TYPE bsis_view OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF dtl OCCURS   0,
        aufnr LIKE caufv-aufnr,
        item  LIKE sy-tabix,
        newko LIKE rf05a-newko,
        objnr LIKE pmco-objnr,
        cocur LIKE pmco-cocur,
        acpos LIKE pmco-acpos,
        kostl LIKE bseg-kostl,
        wrbtr LIKE pmco-wrt04,
        zuonr LIKE bseg-zuonr,
        sgtxt LIKE bseg-sgtxt,
      END OF dtl.

DATA: BEGIN OF wardel_bdg OCCURS 0,
        kstar  TYPE v_cosp_view-kstar,
        kostl  LIKE csks-kostl,
        gsber  LIKE csks-gsber,
        objnr  TYPE v_cosp_view-objnr,
        budget TYPE v_cosp_view-wog001,
        actual TYPE v_cosp_view-wog001,
        saldo  TYPE v_cosp_view-wog001,
      END OF wardel_bdg.

DATA: BEGIN OF list_wo OCCURS 0,
        aufnr  LIKE caufv-aufnr,
        hkont  LIKE bseg-hkont,
        kostl  LIKE bseg-kostl,
        budget TYPE v_cosp_view-wog001,
        actual TYPE v_cosp_view-wog001,
        saldo  TYPE v_cosp_view-wog001,
      END OF list_wo.

"add VTR 2413
DATA: BEGIN OF izaugru OCCURS 0,
        augru   LIKE zaugru-augru,
        augru_d LIKE zaugru-augru_d,
        hkont   LIKE zaugru-hkont,
      END OF izaugru.

DATA: wo_stat(4) VALUE 'TECO',
      baris      LIKE sy-tabix,
      item       LIKE sy-tabix,
      total      LIKE pmco-wrt04,
      cwrbtr     LIKE pmco-wrt04,
      zaufnr     LIKE caufv-aufnr,
      xkdauf     LIKE caufv-kdauf VALUE 1,
      xkdpos     LIKE caufv-kdpos VALUE 1,
      xlgpla     LIKE lagp-lgpla,
      ovh_cost   LIKE pmco-wrt04,
      cost_ovh   LIKE pmco-wrt04,
      ovh_flg(1),
      val_jcs    LIKE pmco-acpos VALUE 'Z50',
      datum(10),
      tbldat(10),
      tbudat(10),
      xwrbtr(11),
      xmode(1)   VALUE 'E',
      xblnr      LIKE bkpf-xblnr,
      ertxt(250) TYPE c,
      t_augru    LIKE zaugru-augru,
      t_augru_d  LIKE zaugru-augru_d,
      gl_sakto   LIKE ekkn-sakto.

TYPES: BEGIN OF ty_databdg,
         kstar  TYPE v_cosp_view-kstar,
         kostl  LIKE csks-kostl,
         gsber  LIKE csks-gsber,
         objnr  TYPE v_cosp_view-objnr,
         twaer  TYPE v_cosp_view-twaer,
         wtg    TYPE v_cosp_view-wtg001,
         budget TYPE v_cosp_view-wog001,
         actual TYPE v_cosp_view-wog001,
         saldo  TYPE v_cosp_view-wog001,
       END OF ty_databdg.
DATA: gt_databdg TYPE TABLE OF ty_databdg,
      gs_databdg TYPE ty_databdg.

*----------------------------------------------------------------------*
* Types & globals for direct email notification (PRD ALT)
*----------------------------------------------------------------------*
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

DATA: gt_recipients TYPE tt_email_recipient.
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE TEXT-001 ##TEXT_POOL.
  SELECT-OPTIONS: p_kdauf FOR caufv-kdauf,
                  p_aufart FOR caufv-auart,
                  p_aufnr FOR caufvd-aufnr,
                  p_werks FOR caufvd-werks,
                  p_addat FOR viaufks-addat. "default sy-datum.
  PARAMETERS: p_bldat LIKE bkpf-bldat DEFAULT sy-datum,
              p_budat LIKE bkpf-budat DEFAULT sy-datum.
SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN BEGIN OF BLOCK blk3 WITH FRAME TITLE TEXT-003 ##TEXT_POOL. "add VTR IT/IS 2413
  SELECT-OPTIONS: s_idat2  FOR caufv-idat2,      "TECO Date
                  s_augru  FOR vbak-augru,       "Order Reason
                  s_augrud FOR zsnmodel-augru_d, "Allocation
                  s_hkont  FOR zaugru-hkont,     "GL Account
                  s_erdat  FOR vbak-erdat.       "PJB Date
SELECTION-SCREEN END OF BLOCK blk3.

SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE TEXT-002 ##TEXT_POOL.
  PARAMETERS: backg AS CHECKBOX,
              test  AS CHECKBOX DEFAULT 'X',
              list  AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK blk2.

INITIALIZATION.
  PERFORM initialization_data.
  PERFORM init_field.
  PERFORM init_event.
  PERFORM init_sort.
  PERFORM init_layout USING layout.

AT SELECTION-SCREEN.
  PERFORM check_entry.

START-OF-SELECTION.
  PERFORM get_service_order.
  PERFORM create_acct_data.
  DESCRIBE TABLE hdr LINES baris.
  IF baris GT 0.
    PERFORM posting_data.
    PERFORM posting_batch.
    PERFORM alv_list.
  ELSE.
    MESSAGE s398(00) WITH TEXT-201 ##MG_MISSING.
    STOP.
  ENDIF.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Form  GET_SERVICE_ORDER
*&---------------------------------------------------------------------*
FORM get_service_order.
  DATA: ls_vbap  TYPE vbap,
        ls_vbak  TYPE vbak,
        lv_found TYPE flag,
        lv_age   TYPE i.
  IF p_aufart IS INITIAL.
    LOOP AT i003o.
      p_aufart-sign = 'I'. p_aufart-option = 'EQ'.
      p_aufart-low  = i003o-auart.
      APPEND p_aufart.
    ENDLOOP.
  ELSE.
    LOOP AT p_aufart.
      READ TABLE i003o WITH KEY auart = p_aufart-low.
      IF sy-subrc NE 0. DELETE p_aufart. ENDIF.
    ENDLOOP.
  ENDIF.
  SELECT * INTO TABLE iaufk FROM viaufks
   WHERE aufnr IN p_aufnr AND autyp EQ '30'
     AND kdauf IN p_kdauf AND idat3 EQ '00000000'
     AND auart IN p_aufart
     AND addat IN p_addat AND werks IN p_werks
     AND idat2 IN s_idat2. "add VTR IT/IS 2413

  "add VTR IT/IS 2413
  SELECT augru augru_d hkont INTO TABLE izaugru FROM zaugru
   WHERE augru   IN s_augru
     AND augru_d IN s_augrud.
  "VTR 2516 AND HKONT   IN S_HKONT.

  DESCRIBE TABLE iaufk LINES baris.
  IF baris GT 0.
    LOOP AT iaufk.
      CALL FUNCTION 'STATUS_TEXT_EDIT' ##FM_SUBRC_OK
        EXPORTING
          objnr             = iaufk-objnr
          spras             = sy-langu
        IMPORTING
          anw_stat_existing = caufvd-astex
          line              = caufvd-sttxt
        EXCEPTIONS
          object_not_found  = 1.
      IF caufvd-sttxt(4) EQ wo_stat.
        MOVE: caufvd-sttxt TO iaufk-sttxt.
        ilagp-lgpla = iaufk-aufnr+2(10).
        APPEND ilagp.
      ELSE.
        iaufk-delet = 'X'.
      ENDIF.
      MODIFY iaufk.
    ENDLOOP.
  ENDIF.
  DELETE iaufk WHERE delet = 'X'.

* Job in Process
  DESCRIBE TABLE ilagp LINES baris.
  IF baris GT 0.
    SELECT lgnum lgtyp lgpla INTO TABLE xlagp FROM lagp
    FOR ALL ENTRIES IN ilagp
    WHERE lgtyp IN ('200', '300') AND lgpla EQ ilagp-lgpla.
  ENDIF.
  CLEAR: iaufk, caufvd.

* Calculate actual cost.
  DESCRIBE TABLE iaufk LINES baris.
  IF baris GT 0.
    SELECT * INTO TABLE hpmco FROM pmco FOR ALL ENTRIES IN iaufk
    WHERE objnr EQ iaufk-objnr AND wrttp EQ '04'.
  ELSE.
    MESSAGE s398(00) WITH TEXT-201 ##MG_MISSING.
    STOP.
  ENDIF.
  LOOP AT iaufk.
    CLEAR: iaufk-acost, ovh_flg, ovh_cost, cost_ovh, baris.
    LOOP AT hpmco WHERE objnr EQ iaufk-objnr.
      CLEAR: total.
      total = hpmco-wrt00 + hpmco-wrt01 + hpmco-wrt02 +
              hpmco-wrt03 + hpmco-wrt04 + hpmco-wrt05 +
              hpmco-wrt06 + hpmco-wrt07 + hpmco-wrt08 +
              hpmco-wrt09 + hpmco-wrt10 + hpmco-wrt11 +
              hpmco-wrt12 + hpmco-wrt13 + hpmco-wrt14 +
              hpmco-wrt15 + hpmco-wrt16.

* Check Overhead -> Overhead must be calculated if Z20 gt 0.
CHECK total NE 0.     "IT IS HD 10509
      IF 'ZSVC ZBSO ZISO ZYRD ZSCH ZIPK ZRNT' CS iaufk-auart.
        CASE hpmco-acpos.
          WHEN 'Z20'.
            cost_ovh = cost_ovh + total.
            IF total GT 0.
              ovh_flg = 'X'.
            ENDIF.
          WHEN 'Z31' OR 'Z32' OR 'Z33'.
            ovh_cost = ovh_cost + total.
        ENDCASE.
      ENDIF.
      iaufk-acost = total + iaufk-acost.
    ENDLOOP.
    IF iaufk-acost EQ 0.
      iaufk-delet = 'X'.
    ELSEIF 'ZSVC ZBSO ZISO ZYRD ZSCH ZIPK ZRNT' CS iaufk-auart.
      IF ovh_flg EQ 'X' AND ovh_cost EQ 0.
        MESSAGE i398(00) WITH 'Overhead calculation for order' ##NO_TEXT
        iaufk-aufnr 'not yet been executed' ##MG_MISSING ##NO_TEXT.
        iaufk-delet = 'X'.
        PERFORM insert_error USING '1' iaufk-aufnr TEXT-501 ##TEXT_POOL.
      ENDIF.
    ENDIF.
* Check Job in Process (JIP)
    xlgpla = iaufk-aufnr+2(10).
    READ TABLE xlagp WITH KEY lgpla = xlgpla.
    IF sy-subrc EQ 0.
      MESSAGE i398(00) WITH 'Found Job in Process (JIP)'
        'quantity in Order' iaufk-aufnr ##MG_MISSING ##NO_TEXT.
      iaufk-delet = 'X'.
      PERFORM insert_error USING '2' iaufk-aufnr TEXT-502 ##TEXT_POOL.
    ENDIF.
* Check JCS -> Order delete if JCS has been processed
    IF iaufk-aufnr NE '000050057811'.
      READ TABLE hpmco WITH KEY objnr = iaufk-objnr
                                acpos = val_jcs.
      IF sy-subrc EQ 0.
        CLEAR: total.
        LOOP AT hpmco WHERE objnr = iaufk-objnr AND
                                acpos = val_jcs.
        total = total + hpmco-wrt00 + hpmco-wrt01 + hpmco-wrt02 +
                hpmco-wrt03 + hpmco-wrt04 + hpmco-wrt05 +
                hpmco-wrt06 + hpmco-wrt07 + hpmco-wrt08 +
                hpmco-wrt09 + hpmco-wrt10 + hpmco-wrt11 +
                hpmco-wrt12 + hpmco-wrt13 + hpmco-wrt14 +
                hpmco-wrt15 + hpmco-wrt16.
        ENDLOOP.
        IF total NE 0.
          iaufk-delet = 'X'.
          PERFORM insert_error USING '7' iaufk-aufnr TEXT-507 ##TEXT_POOL.
        ENDIF.
      ENDIF.
      MODIFY iaufk.
    ENDIF.
*    start insertion implementation
*    IT/IS 626 : Lock/control SR Intemal Service (for Mcchanic Development only) - Transfer cost and Check Budget
    CLEAR lv_found.
    CALL FUNCTION 'ZFM_SVC_GET_SRD'
      EXPORTING
        e_vbeln = iaufk-kdauf
      CHANGING
        i_vbak  = ls_vbak
        i_vbap  = ls_vbap
        i_found = lv_found.
    IF lv_found = space.
    ELSE.
                                                            "VTR 2516
      READ TABLE izaugru WITH KEY augru = ls_vbak-augru.
      IF sy-subrc EQ 0.
        IF ls_vbak-augru EQ 'PRT' OR
          ls_vbak-augru EQ 'MKT' OR
          ls_vbak-augru EQ 'GAD'." OR
*            ls_vbak-augru EQ 'SVC'. "commented temporary
          SELECT SINGLE * FROM zsvctdtl
              WHERE aufnr = iaufk-aufnr  AND
                    approved = 'X'.
          IF sy-subrc NE 0.
            CLEAR lv_age.
            CALL FUNCTION 'DAYS_BETWEEN_TWO_DATES' ##FM_SUBRC_OK
              EXPORTING
                i_datum_bis             = sy-datum
                i_datum_von             = iaufk-idat2
              IMPORTING
                e_tage                  = lv_age
              EXCEPTIONS
                days_method_not_defined = 1
                OTHERS                  = 2.
            IF lv_age LE 7 AND iaufk-idat2 NE '00000000'.
              MESSAGE i000(db) WITH 'Order' ##NO_TEXT iaufk-aufnr 'Need Approval' ##MG_MISSING ##NO_TEXT.
              iaufk-delet = 'X'.
            ENDIF.
          ELSE.

          ENDIF.
        ELSE.

        ENDIF.
      ELSE.
        iaufk-delet = 'X'.
      ENDIF.
    ENDIF.
    MODIFY iaufk.
*     end of insertion IT/IS 626
  ENDLOOP.
  DELETE iaufk WHERE delet = 'X'.
* Collect Service Order
  DESCRIBE TABLE iaufk LINES baris.
  IF baris GT 0.
    SELECT * INTO TABLE hcaufv FROM caufv FOR ALL ENTRIES IN iaufk
    WHERE aufnr EQ iaufk-aufnr.
  ELSE.
    MESSAGE s398(00) WITH TEXT-201 ##MG_MISSING. STOP.
  ENDIF.
ENDFORM.                    " GET_SERVICE_ORDER

*&---------------------------------------------------------------------*
*&      Form  CREATE_ACCT_DATA
*&---------------------------------------------------------------------*
FORM create_acct_data.
  LOOP AT iaufk.
    CLEAR: hdr, ccd_txt.
    MOVE-CORRESPONDING iaufk TO hdr.
*    Sales Order data
    IF hdr-auart = 'ZBSO' AND iaufk-lead_aufnr NE space.
      SELECT SINGLE * FROM caufv WHERE aufnr = iaufk-lead_aufnr.
      IF sy-subrc = 0 AND caufv-auart = 'ZSCH'.
        PERFORM caufv_read USING iaufk-lead_aufnr
                       CHANGING hdr-lauart hdr-lwerks hdr-lgsber.
      ENDIF.
    ENDIF.

    CHECK hdr-kdauf NE space.

    SELECT SINGLE * FROM vbak WHERE vbeln EQ hdr-kdauf.
    CHECK 'ZSRF ZSRW ZSRD ZSRI ZFMI ZFMC ZCRN' CS vbak-auart. "ZFMC add vita 11/05/2015 IT/IS 1243

    PERFORM get_salesdata USING hdr-aufnr hdr-auart hdr-kdauf hdr-kdpos
                       CHANGING hdr-delet.
    IF iaufk-auart EQ 'ZSVC' AND hdr-vaugru = 'SVC'.
      hdr-delet = 'X'.
    ENDIF.
    CHECK hdr-delet IS INITIAL.
*    Leading order
    IF NOT iaufk-lead_aufnr IS INITIAL.
      MOVE: iaufk-lead_aufnr TO hdr-laufnr.
      PERFORM caufv_read USING iaufk-lead_aufnr
                      CHANGING hdr-lauart hdr-lwerks hdr-lgsber.
      IF iaufk-auart EQ 'ZSVC' AND hdr-lauart NE 'ZISO'.
        hdr-delet = 'X'.
      ENDIF.
    ENDIF.
*    Superior order
    IF NOT iaufk-maufnr IS INITIAL.
      PERFORM caufv_read USING iaufk-lead_aufnr
                      CHANGING hdr-mauart hdr-mwerks hdr-mgsber.
    ENDIF.
    CHECK hdr-delet NE 'X'.
*    Order reason
    IF hdr-vaugru EQ 'SVC' OR hdr-vaugru EQ 'FMC'.
*       Changed by DNY 29.08.2007
*       Initiate for SVC inter branch
      IF hdr-vspart EQ hdr-uspart AND hdr-auart NE 'ZIPK'.
        hdr-delet = 'X'.
      ENDIF.
*       End by DNY 29.08.2007
    ELSEIF hdr-vaugru EQ 'RDO'.
      IF hdr-auart NE 'ZBSO' AND hdr-auart NE 'ZIPK'.
        hdr-delet = 'X'.
      ENDIF.
    ENDIF.
    CHECK hdr-delet NE 'X'.
    IF NOT hdr-vaugru IS INITIAL.
      IF 'ZISO ZSCH ZYRD ZBSO ZIPK ZSVC ZRNT' CS hdr-auart.
        PERFORM order_reason USING hdr-vaugru hdr-vaugru_d hdr-ilart
                                   hdr-vkunnr hdr-ubstzd
                          CHANGING hdr-akunnr hdr-azuonr hdr-ahkont
                                   hdr-delet.
      ENDIF.
    ENDIF.
    IF hdr-vaugru EQ 'SVC' OR hdr-vaugru EQ 'FMC'.
*       Changed by DNY 29.08.2007
*       Initiate for SVC inter branch
      IF hdr-vspart EQ hdr-uspart AND hdr-auart NE 'ZIPK'.
        hdr-delet = 'X'.
      ENDIF.
*       End by DNY 29.08.2007
    ENDIF.
    CHECK hdr-delet NE 'X'.
    CASE hdr-auart.
      WHEN 'ZISO'. PERFORM auart_ziso.
      WHEN 'ZSCH'. PERFORM auart_zsch.
      WHEN 'ZYRD'. PERFORM auart_zyrd.
      WHEN 'ZBSO'. PERFORM auart_zbso.
      WHEN 'ZSVC'. PERFORM auart_zbso.
      WHEN 'ZPTS'. PERFORM auart_zpts.
      WHEN 'ZPRT'. PERFORM auart_zprt.
      WHEN 'ZIPK'. PERFORM auart_zipk.
      WHEN 'ZRNT'. PERFORM auart_zrnt.
    ENDCASE.
    CHECK hdr-delet NE 'X'.
    APPEND hdr.
  ENDLOOP.
  SORT hdr BY aufnr.
  LOOP AT hdr.
    CLEAR: dtl-item, total.
    LOOP AT hpmco WHERE objnr EQ hdr-objnr AND wrttp EQ '04'.
      IF hdr-auart = 'ZIPK' AND NOT ( hdr-vkunnr = 'BRANCH' ). "hdr-ukostl EQ hdr-vkostl.
        CHECK hpmco-acpos NE 'Z10'.
        CHECK hpmco-acpos NE 'Z41'.
        CHECK hpmco-acpos NE 'Z90'.
      ENDIF.
      CLEAR: dtl.
      ADD 1 TO dtl-item.
      MOVE-CORRESPONDING hpmco TO dtl.
      dtl-aufnr = hdr-aufnr.
      dtl-wrbtr = hpmco-wrt00 + hpmco-wrt01 + hpmco-wrt02 +
                  hpmco-wrt03 + hpmco-wrt04 + hpmco-wrt05 +
                  hpmco-wrt06 + hpmco-wrt07 + hpmco-wrt08 +
                  hpmco-wrt09 + hpmco-wrt10 + hpmco-wrt11 +
                  hpmco-wrt12 + hpmco-wrt13 + hpmco-wrt14 +
                  hpmco-wrt15 + hpmco-wrt16.
      CHECK dtl-wrbtr NE 0.
      PERFORM read_acpos USING dtl-acpos CHANGING dtl-sgtxt.
*        APPEND DTL.
      COLLECT dtl.
      total = total + dtl-wrbtr.
    ENDLOOP.
    CLEAR: dtl-acpos, dtl-item.
    IF total GT 0.
      dtl-wrbtr = total.
    ELSE.
      hdr-delet = 'X'.
    ENDIF.
    MODIFY hdr.
  ENDLOOP.
  DELETE hdr WHERE delet NE space.
  LOOP AT iaufk.
    READ TABLE hdr WITH KEY aufnr = iaufk-aufnr.
    IF sy-subrc NE 0.
      iaufk-idat3 = sy-datum.
      xaufk-aufnr = iaufk-aufnr. APPEND xaufk.
      MODIFY iaufk.
    ENDIF.
  ENDLOOP.
  CLEAR: hdr, dtl.
  SORT hdr BY aufnr. SORT dtl BY aufnr item.
ENDFORM.                    " CREATE_ACCT_DATA

*&---------------------------------------------------------------------*
*&      Form  ORDER_REASON
*&---------------------------------------------------------------------*
FORM order_reason USING    p_augru VALUE(p_augru_d) p_ilart p_kunnr p_ubstzd
                  CHANGING p_vkunnr p_zuonr p_hkont p_delet.

  CLEAR: p_vkunnr, p_zuonr, p_hkont.
  IF p_augru_d IS INITIAL.
    IF p_augru EQ 'MKT'.
      READ TABLE iaugru WITH KEY augru = p_augru
                                 kunag = p_kunnr.
      IF sy-subrc EQ 0.
        p_vkunnr  = iaugru-kunag.
        p_zuonr   = iaugru-zuonr.
        p_hkont   = iaugru-hkont.
        p_augru_d = iaugru-augru_d.
      ELSE.
        p_delet = 'X'.
        MESSAGE i398(00) WITH 'Error Order Reason' p_augru p_kunnr
                               hdr-aufnr ##NO_TEXT.
      ENDIF.
    ELSE.
      READ TABLE iaugru WITH KEY augru = p_augru.
      IF sy-subrc EQ 0.
        p_vkunnr  = iaugru-kunag.
        p_zuonr   = iaugru-zuonr.
        p_hkont   = iaugru-hkont.
        p_augru_d = iaugru-augru_d.
      ELSE.
        p_delet = 'X'.
        MESSAGE i398(00) WITH 'Error Order Reason' p_augru ##MG_MISSING ##NO_TEXT.
      ENDIF.
    ENDIF.
  ELSE.
    IF p_augru EQ 'MKT'.
      READ TABLE iaugru WITH KEY augru   = p_augru
                                 augru_d = p_augru_d
                                 kunag   = p_kunnr.
      IF sy-subrc EQ 0.
        p_vkunnr  = iaugru-kunag.
        p_zuonr   = iaugru-zuonr.
        p_hkont   = iaugru-hkont.
        p_augru_d = iaugru-augru_d.
      ELSE.
        p_delet = 'X'.
        MESSAGE i398(00) WITH 'Error Order Reason' ##NO_TEXT
                p_augru p_augru_d p_kunnr.
      ENDIF.
    ELSE.
      READ TABLE iaugru WITH KEY augru   = p_augru
                                 augru_d = p_augru_d.
      IF sy-subrc EQ 0.
        p_vkunnr  = iaugru-kunag.
        p_zuonr   = iaugru-zuonr.
        p_hkont   = iaugru-hkont.
        p_augru_d = iaugru-augru_d.
      ELSE.
        p_delet = 'X'.
        MESSAGE i398(00) WITH 'Error Order Reason'
                p_augru p_augru_d ##MG_MISSING ##NO_TEXT.
      ENDIF.
    ENDIF.
  ENDIF.
                                                            "VTR 2516
  READ TABLE izaugru WITH KEY augru   = p_augru
                              augru_d = p_augru_d.
  IF sy-subrc EQ 0.

  ELSE.
    p_delet = 'X'.
  ENDIF.
* Changed 291004 for UTHI
  IF p_ubstzd EQ 'UTHI'.
    p_hkont = '7100000004'.
  ENDIF.
ENDFORM.                    " ORDER_REASON

*&---------------------------------------------------------------------*
*&      Form  AUART_ZISO
*&---------------------------------------------------------------------*
FORM auart_ziso.
  IF hdr-vauart EQ 'ZSRI'.
    hdr-newd1 = '6562000005'.      "Cost Service JCS
    hdr-newc1 = '6562000005'.      "Cost Service JCS
    hdr-newd2 = hdr-ahkont.        "Cost by order reason
    hdr-newc2 = '6562000005'.      "Cost Service JCS
  ELSE.
    hdr-delet = 'X'.
  ENDIF.
ENDFORM.                    " AUART_ZISO

*&---------------------------------------------------------------------*
*&      Form  AUART_ZSCH
*&---------------------------------------------------------------------*
FORM auart_zsch.
  IF 'ZSRD ZSRI' CS hdr-vauart.
    hdr-newd1 = '6562000005'.      "Cost Service JCS
    hdr-newc1 = '6562000005'.      "Cost Service JCS
    hdr-newd2 = hdr-ahkont.        "Cost by order reason
    hdr-newc2 = '6562000005'.      "Cost Service JCS
  ELSE.
    hdr-delet = 'X'.
  ENDIF.
ENDFORM.                    " AUART_ZSCH

*&---------------------------------------------------------------------*
*&      Form  AUART_ZYRD
*&---------------------------------------------------------------------*
FORM auart_zyrd.
  IF hdr-vauart EQ 'ZSRD'.
    hdr-newd1 = '6562000005'.      "Cost Service JCS
    hdr-newc1 = '6562000005'.      "Cost Service JCS
    hdr-newd2 = hdr-ahkont.        "Cost by order reason
    hdr-newc2 = '6562000005'.      "Cost Service JCS
  ELSE.
    hdr-delet = 'X'.
  ENDIF.
ENDFORM.                    " AUART_ZYRD

*&---------------------------------------------------------------------*
*&      Form  AUART_ZPTS
*&---------------------------------------------------------------------*
FORM auart_zpts.
  IF hdr-werks NE hdr-lwerks.
    hdr-newd2 = '6520100003'.  "Cost Parts: PTS
    hdr-newc2 = '6520100003'.  "Cost Parts: PTS
  ELSE.
    hdr-delet = 'X'.
  ENDIF.
  SELECT SINGLE * FROM caufv WHERE lead_aufnr EQ hdr-laufnr
     AND auart EQ hdr-auart AND werks EQ hdr-lwerks.
  IF sy-subrc EQ 0.
    hdr-taufnr = caufv-aufnr.
    hdr-tauart = caufv-auart.
    hdr-twerks = caufv-werks.
    hdr-tgsber = caufv-gsber.
  ELSE.
    MESSAGE e398(00) WITH 'No PTS order in destination plant' ##MG_MISSING ##NO_TEXT.
  ENDIF.
ENDFORM.                    " AUART_ZPTS

*&---------------------------------------------------------------------*
*&      Form  AUART_ZPRT
*&---------------------------------------------------------------------*
FORM auart_zprt.
  hdr-newd1 = '6520100099'.     "Cost Parts Others
  hdr-newc1 = '6562000005'.     "Cost Service JCS
*  IF HDR-WERKS NE HDR-LWERKS.   "Antar Cabang
*     HDR-NEWD2 = '6520100099'.  "Cost Parts Others
*     HDR-NEWC2 = '6520100099'.  "Cost Parts Others
*  ENDIF.
ENDFORM.                    " AUART_ZPRT

*&---------------------------------------------------------------------*
*&      Form  AUART_ZBSO
*&---------------------------------------------------------------------*
FORM auart_zbso.
  IF NOT hdr-maufnr IS INITIAL.
    CASE hdr-vauart.
      WHEN 'ZSRI'.
        hdr-newd1 = '6562000005'.      "Cost Service JCS
        hdr-newc1 = '6562000005'.      "Cost Service JCS
        hdr-newd2 = hdr-ahkont.        "Cost by order reason
        hdr-newc2 = '6562000005'.      "Cost Service JCS
      WHEN 'ZFMC'.
        hdr-newd1 = '6562000005'.     "Cost Service JCS
        hdr-newc1 = '6562000005'.     "Cost Service JCS
        hdr-newd2 = '6563000005'.     "Cost FMC JCS
        hdr-newc2 = '6562000005'.     "Cost Service JCS
      WHEN OTHERS.
        hdr-newd1 = '6562000005'.     "Cost Service JCS
        hdr-newc1 = '6562000005'.     "Cost Service JCS
        hdr-newd2 = '6562000005'.     "Cost Service JCS
        hdr-newc2 = '6562000005'.     "Cost Service JCS
    ENDCASE.
  ENDIF.
ENDFORM.                    " AUART_ZBSO
*&---------------------------------------------------------------------*
*&      Form  GET_SALESDATA
*&---------------------------------------------------------------------*
FORM get_salesdata USING p_aufnr p_auart p_kdauf p_kdpos
                CHANGING p_delet.
* Sales Header
  SELECT SINGLE * FROM vbak WHERE vbeln EQ p_kdauf.
  IF sy-subrc EQ 0.
    MOVE: vbak-vkorg TO hdr-vvkorg,
          vbak-vtweg TO hdr-vvtweg,
          vbak-spart TO hdr-vspart,
          vbak-auart TO hdr-vauart,
          vbak-augru TO hdr-vaugru,
          vbak-vkbur TO hdr-vvkbur,
          vbak-vgbel TO hdr-vvgbel,
          vbak-kunnr TO hdr-vkunnr.
* Sales Detail
    SELECT SINGLE * FROM vbap WHERE vbeln EQ p_kdauf
                                AND posnr EQ p_kdpos.
    IF sy-subrc EQ 0.
      MOVE: vbap-matnr TO hdr-vmatnr,
            vbap-pstyv TO hdr-vpstyv,
            vbap-werks TO hdr-vwerks,
            vbap-uepos TO hdr-vuepos,
            vbap-vgpos TO hdr-vvgpos.
      IF hdr-vuepos IS INITIAL. hdr-vuepos = 10. ENDIF.
      IF hdr-vvgpos IS INITIAL. hdr-vvgpos = hdr-vuepos. ENDIF.
    ELSE.
      p_delet = 'X'.
      CONCATENATE p_aufnr p_kdauf p_kdpos INTO tmess
          SEPARATED BY '/'.
      MESSAGE i398(00) WITH TEXT-506 ##TEXT_POOL tmess ##MG_MISSING.
      PERFORM insert_error USING '6' p_aufnr tmess.
    ENDIF.
* Order Reason Detail
    IF 'ZSRD ZSRI' CS vbak-auart.
      IF p_auart EQ 'ZSCH'.
        hdr-vaugru_d = 'SER'.
*       021105 for ReDo Antar Cabang
      ELSEIF p_auart EQ 'ZBSO' AND hdr-vaugru EQ 'RDO'.
        hdr-vaugru_d = 'SVC'.
      ELSEIF p_auart EQ 'ZBSO' AND hdr-lauart = 'ZSCH'.
        hdr-vaugru_d = 'SER'.
*       120407 for ReDo Remanufacturing
      ELSEIF p_auart EQ 'ZIPK'.
        CASE hdr-vaugru.
          WHEN 'RDO'. hdr-vaugru_d = 'PRT'.
          WHEN 'SLS'. hdr-vaugru_d = 'WAR'.
          WHEN 'PRT'. hdr-vaugru_d = 'PWR'.
          WHEN 'SVC'.
            SELECT SINGLE * FROM zsnmodel WHERE vbeln EQ p_kdauf
                                        AND posnr EQ p_kdpos.
            IF sy-subrc EQ 0.
              MOVE: zsnmodel-augru_d TO hdr-vaugru_d.
            ELSE.
              p_delet = 'X'.
              CONCATENATE p_aufnr p_kdauf p_kdpos INTO tmess
                  SEPARATED BY '/'.
              MESSAGE i398(00) WITH TEXT-504 ##TEXT_POOL tmess ##MG_MISSING.
              PERFORM insert_error USING '4' p_aufnr tmess.
            ENDIF.
            IF hdr-vaugru_d IS INITIAL.
              hdr-delet = 'X'.
              CONCATENATE p_aufnr p_kdauf p_kdpos INTO tmess
                 SEPARATED BY '/'.
              MESSAGE i398(00) WITH TEXT-503 ##TEXT_POOL tmess ##MG_MISSING.
              PERFORM insert_error USING '3' p_aufnr tmess.
            ENDIF.
            "start VTR IT/IS 2413
            IF s_erdat IS NOT INITIAL.
              SELECT SINGLE * FROM equi WHERE equnr EQ zsnmodel-equnr.
              IF sy-subrc EQ 0.
                SELECT SINGLE * FROM zusernr
                WHERE bismt EQ equi-typbz AND "#EC CI_FLDEXT_OK[2215424]
                      sernr EQ equi-sernr AND
                      vbeln NE space.
                IF sy-subrc EQ 0.
                  SELECT SINGLE * FROM vbak
                  WHERE vbeln EQ zusernr-vbeln.
                  IF vbak-erdat IN s_erdat.
                  ELSE.
                    p_delet = 'X'.
                  ENDIF.
                ELSE.
                  p_delet = 'X'.
                ENDIF.
              ELSE.
                p_delet = 'X'.
              ENDIF.
            ENDIF.
            "end VTR IT/IS 2413
          WHEN OTHERS.
        ENDCASE.
      ELSE.
        SELECT SINGLE * FROM zsnmodel WHERE vbeln EQ p_kdauf
                                        AND posnr EQ p_kdpos.
        IF sy-subrc EQ 0.
          MOVE: zsnmodel-augru_d TO hdr-vaugru_d.
          IF hdr-vaugru_d IS INITIAL.
            hdr-delet = 'X'.
            CONCATENATE p_aufnr p_kdauf p_kdpos INTO tmess
               SEPARATED BY '/'.
            MESSAGE i398(00) WITH TEXT-503 ##TEXT_POOL tmess ##MG_MISSING.
            PERFORM insert_error USING '3' p_aufnr tmess.
          ENDIF.
          "start VTR IT/IS 2413
          IF s_erdat IS NOT INITIAL.
            SELECT SINGLE * FROM equi WHERE equnr EQ zsnmodel-equnr.
            IF sy-subrc EQ 0.
              SELECT SINGLE * FROM zusernr
              WHERE bismt EQ equi-typbz AND  "#EC CI_FLDEXT_OK[2215424]
                    sernr EQ equi-sernr AND
                    vbeln NE space.
              IF sy-subrc EQ 0.
                SELECT SINGLE * FROM vbak
                WHERE vbeln EQ zusernr-vbeln.
                IF vbak-erdat IN s_erdat.
                ELSE.
                  p_delet = 'X'.
                ENDIF.
              ELSE.
                p_delet = 'X'.
              ENDIF.
            ELSE.
              p_delet = 'X'.
            ENDIF.
          ENDIF.
          "end VTR IT/IS 2413
        ELSE.
          p_delet = 'X'.
          CONCATENATE p_aufnr p_kdauf p_kdpos INTO tmess
              SEPARATED BY '/'.
          MESSAGE i398(00) WITH TEXT-504 ##TEXT_POOL tmess ##MG_MISSING.
          PERFORM insert_error USING '4' p_aufnr tmess.
        ENDIF.
      ENDIF.
      CHECK p_delet NE 'X'.
      IF hdr-vkunnr(3) EQ 'MKT' OR hdr-vkunnr EQ 'BRANCH'.
        CONCATENATE hdr-vaugru hdr-vaugru_d hdr-vkunnr INTO tmess
               SEPARATED BY '/'.
        READ TABLE iaugru WITH KEY augru   = hdr-vaugru
                                   augru_d = hdr-vaugru_d
                                   kunag   = hdr-vkunnr.
      ELSE.
        CONCATENATE hdr-vaugru hdr-vaugru_d INTO tmess
               SEPARATED BY '/'.
        READ TABLE iaugru WITH KEY augru   = hdr-vaugru
                                   augru_d = hdr-vaugru_d.
      ENDIF.
      IF sy-subrc NE 0.
        p_delet = 'X'.
        MESSAGE i398(00) WITH TEXT-505 ##TEXT_POOL 'for' tmess ##MG_MISSING.
        PERFORM insert_error USING '5' p_aufnr tmess.
      ENDIF.
    ENDIF.
    CHECK p_delet IS INITIAL.
* Cost Center Determination
    IF NOT vbak-augru IS INITIAL.
* Change 291004 for UTHI
      IF vbak-bstzd EQ 'UTHI'.
        hdr-vkostl = '01MNG'.
        hdr-vgskst = 'CMO'.
      ELSE.
        IF vbak-augru(3) EQ 'GAD'.
          t_augru = hdr-vaugru_d.
          "IT IS 5908 21 Des 2021
        ELSEIF vbak-augru(3) EQ 'RTL'. " Order Reason Rental
          t_augru = 'SVC'.
        ELSE.
          t_augru = hdr-vaugru.
        ENDIF.
        READ TABLE itvauk WITH KEY vkorg = vbak-vkorg
                                   vtweg = vbak-vtweg
                                   spart = hdr-vspart
                                   augru = t_augru.
        IF sy-subrc EQ 0.
          MOVE: itvauk-kostl TO hdr-vkostl,
                itvauk-gskst TO hdr-vgskst.
        ELSE.
          CONCATENATE vbak-vkorg vbak-vtweg hdr-vspart t_augru
             vbak-vbeln INTO ccdet SEPARATED BY '/'.
          MESSAGE i398(00) WITH TEXT-505 ##TEXT_POOL ccdet ##MG_MISSING.
          PERFORM insert_error USING '5' p_aufnr ccdet.
          p_delet = 'X'.
        ENDIF.
      ENDIF.
    ENDIF.
  ELSE.
    p_delet = 'X'.
    MESSAGE i398(00) WITH 'Sales document' ##NO_TEXT p_kdauf 'not found' ##MG_MISSING ##NO_TEXT.
  ENDIF.
  CHECK p_delet IS INITIAL.
* Sales Reference for Internal ( Get BA and Cost Center)
  CASE vbak-auart.
    WHEN 'ZSRI'.
      SELECT SINGLE spart auart augru bstzd INTO
            (hdr-uspart, hdr-uauart, hdr-uaugru, hdr-ubstzd)
       FROM vbak WHERE vbeln EQ vbak-vgbel.
    WHEN 'ZSRD' OR 'ZCRN'.
      SELECT SINGLE spart auart augru bstzd INTO
             (hdr-uspart, hdr-uauart, hdr-uaugru, hdr-ubstzd)
        FROM vbak WHERE vbeln EQ vbak-vbeln.
  ENDCASE.
* Cost Center Determination for Upper level SR
  IF NOT hdr-uaugru IS INITIAL.
* Change 291004 for UTHI
    IF hdr-ubstzd EQ 'UTHI'.
      hdr-ukostl = '01MNG'.
      hdr-ugskst = 'CMO'.
    ELSE.
      IF vbak-augru(3) EQ 'GAD'.
        t_augru = hdr-vaugru_d.
        "IT IS 5908 21 Des 2021
      ELSEIF vbak-augru(3) EQ 'RTL'. " Order Reason Rental
        t_augru = 'SVC'.
      ELSE.
        t_augru = hdr-uaugru.
      ENDIF.
      READ TABLE itvauk WITH KEY vkorg = vbak-vkorg
                                 vtweg = vbak-vtweg
                                 spart = hdr-uspart
                                 augru = t_augru.
      IF sy-subrc EQ 0.
        MOVE: itvauk-kostl TO hdr-ukostl,
              itvauk-gskst TO hdr-ugskst.
      ELSE.
        CONCATENATE vbak-vkorg vbak-vtweg hdr-uspart t_augru
           vbak-vbeln INTO ccdet SEPARATED BY '/'.
        MESSAGE i398(00) WITH TEXT-505 ##TEXT_POOL ccdet ##MG_MISSING.
        PERFORM insert_error USING '5' p_aufnr ccdet.
        p_delet = 'X'.
      ENDIF.
    ENDIF.
  ENDIF.

*  IF 'ZDSH ZSSH' CS VBAP-PSTYV. P_DELET = 'X'. ENDIF.
  CHECK p_delet IS INITIAL.
* Schedule Line data / Leading Order
  SELECT SINGLE * FROM vbep WHERE vbeln EQ p_kdauf
                              AND posnr EQ p_kdpos.
  IF sy-subrc EQ 0.
    MOVE: vbep-aufnr TO hdr-laufnr.
    SELECT SINGLE * FROM aufk WHERE aufnr EQ hdr-laufnr.
    IF sy-subrc EQ 0.
      MOVE: aufk-auart TO hdr-lauart,
            aufk-werks TO hdr-lwerks,
            aufk-gsber TO hdr-lgsber.
    ENDIF.
  ENDIF.
ENDFORM.                    " GET_SALESDATA

*&---------------------------------------------------------------------*
*&      Form  POSTING_DATA
*&---------------------------------------------------------------------*
FORM posting_data.
  DATA: ls_vbap   TYPE vbap,
        ls_vbak   TYPE vbak,
        lv_found  TYPE flag,
        lv_age    TYPE i,
        lv_del(1).
  SORT hdr BY kdauf.
  LOOP AT hdr.
    MOVE-CORRESPONDING hdr TO thdr.
    thdr-seque = 1.
    MOVE: p_bldat TO thdr-bldat,
          p_budat TO thdr-budat,
          'YA'    TO thdr-blart,     "Document Type
          p_budat+4(2) TO thdr-monat.
*           THDR-BLDAT+4(2) TO THDR-MONAT.
    IF hdr-vauart EQ 'ZSRI'.
      CONCATENATE hdr-vvgbel hdr-vvgpos INTO thdr-bktxt
      SEPARATED BY '/'.
    ELSE.
      CONCATENATE hdr-kdauf hdr-kdpos INTO thdr-bktxt
      SEPARATED BY '/'.
    ENDIF.
    MOVE icon_release TO thdr-indictr.
    thdr-posting = '0'.
    APPEND thdr.
    CLEAR: item.
    CASE hdr-auart.
      WHEN 'ZISO' OR 'ZYRD' OR 'ZSCH'.
        PERFORM posting_ziso.
      WHEN 'ZBSO' OR 'ZSVC'.
        IF 'ZSRD ZSRI' CS hdr-vauart.
* Add by DNY 021205 for RDO Antar Cabang
          IF hdr-vaugru EQ 'RDO'.
            PERFORM posting_zbso.
          ELSE.
            PERFORM posting_ziso.
          ENDIF.
        ELSE.
          PERFORM posting_zbso.
        ENDIF.
      WHEN 'ZPTS'.
        PERFORM posting_zpts.
      WHEN 'ZPRT'.
        PERFORM posting_zprt.
      WHEN 'ZIPK'.
        PERFORM posting_zipk.
      WHEN 'ZRNT'.
        PERFORM posting_zrnt.
    ENDCASE.
  ENDLOOP.

  INSERT LINES OF zhdr INTO TABLE thdr.
  SORT thdr BY aufnr seque.
  SORT tdtl BY aufnr seque newbs acpos.


*/ Added by dnm on 24 jun 14
  CLEAR   : wardel_bdg, list_wo.
  REFRESH : wardel_bdg, list_wo.

  LOOP AT tdtl WHERE newbs = '40' OR ( newko = '7100000007' ).
    wardel_bdg-kstar = tdtl-newko.
    wardel_bdg-kostl = tdtl-kostl.
    wardel_bdg-gsber = tdtl-gsber.
    list_wo-hkont    = tdtl-newko.
    list_wo-aufnr    = tdtl-aufnr.
    list_wo-kostl    = tdtl-kostl.
    APPEND wardel_bdg.
    APPEND list_wo.
    CLEAR : list_wo, wardel_bdg.
  ENDLOOP.

  SORT wardel_bdg ASCENDING BY kostl.
  SORT list_wo    ASCENDING BY kostl.
  DELETE ADJACENT DUPLICATES FROM wardel_bdg.
  DELETE ADJACENT DUPLICATES FROM list_wo.


** Get Budget and Actual Posting by GL + CstCenter
  LOOP AT wardel_bdg.
    SELECT SINGLE * FROM csks WHERE kokrs = 'COUT' AND
                                    kostl = wardel_bdg-kostl.
    IF sy-subrc = 0.
      wardel_bdg-objnr = csks-objnr.
******* Get Budget
      CLEAR   itab_cosp.
      REFRESH itab_cosp.
      SELECT * INTO CORRESPONDING FIELDS OF  TABLE @itab_cosp FROM v_cosp_view "cosp
      WHERE objnr = @csks-objnr AND
            gjahr = @p_budat(4) AND
            versn = '000'      AND
            wrttp = '01'       AND
            kstar = @wardel_bdg-kstar.

      LOOP AT itab_cosp WHERE wrttp = '01'.
        CASE p_budat+4(2).
          WHEN '01'.
            wardel_bdg-budget = itab_cosp-wog001.
          WHEN '02'.
            wardel_bdg-budget = itab_cosp-wog002.
          WHEN '03'.
            wardel_bdg-budget = itab_cosp-wog003.
          WHEN '04'.
            wardel_bdg-budget = itab_cosp-wog004.
          WHEN '05'.
            wardel_bdg-budget = itab_cosp-wog005.
          WHEN '06'.
            wardel_bdg-budget = itab_cosp-wog006.
          WHEN '07'.
            wardel_bdg-budget = itab_cosp-wog007.
          WHEN '08'.
            wardel_bdg-budget = itab_cosp-wog008.
          WHEN '09'.
            wardel_bdg-budget = itab_cosp-wog009.
          WHEN '10'.
            wardel_bdg-budget = itab_cosp-wog010.
          WHEN '11'.
            wardel_bdg-budget = itab_cosp-wog011.
          WHEN '12'.
            wardel_bdg-budget = itab_cosp-wog012.
        ENDCASE.
      ENDLOOP.

******* Get Actual
      CLEAR   itab_bsis.
      REFRESH itab_bsis.
      SELECT * FROM bsis_view INTO TABLE @itab_bsis
      WHERE bukrs = 'PTUT'           AND
            hkont = @wardel_bdg-kstar AND
            gsber = @wardel_bdg-gsber AND
            kostl = @wardel_bdg-kostl AND
            monat = @p_budat+4(2)     AND
            gjahr = @p_budat(4).
      LOOP AT itab_bsis.
        IF itab_bsis-shkzg = 'S'.
          wardel_bdg-actual = wardel_bdg-actual +  itab_bsis-dmbtr.
        ELSE.
          wardel_bdg-actual = wardel_bdg-actual - itab_bsis-dmbtr.
        ENDIF.
      ENDLOOP.

******* Get Saldo Budget ( = Budget - Actual )
      wardel_bdg-saldo = wardel_bdg-budget - wardel_bdg-actual.

      MODIFY wardel_bdg.
      CLEAR  wardel_bdg.
    ENDIF.
  ENDLOOP.

* start insertion implementation
* IT/IS 626 : Lock/control SR Intemal Service (for Mcchanic Development only) - Transfer cost and Check Budget
  LOOP AT tdtl WHERE newbs = '40'.
    IF iaufk-aufnr NE tdtl-aufnr.
      READ TABLE iaufk WITH KEY aufnr = tdtl-aufnr.
      CHECK sy-subrc = 0.
    ENDIF.
    CALL FUNCTION 'ZFM_SVC_GET_SRD'
      EXPORTING
        e_vbeln = iaufk-kdauf
      CHANGING
        i_vbak  = ls_vbak
        i_vbap  = ls_vbap
        i_found = lv_found.
    IF lv_found = space.
    ELSE.
      IF ls_vbak-augru EQ 'PRT' OR
        ls_vbak-augru EQ 'MKT' OR
        ls_vbak-augru EQ 'GAD'." OR
*        ls_vbak-augru EQ 'SVC'.
        SELECT SINGLE * FROM zsvctdtl
            WHERE aufnr = tdtl-aufnr AND
                  acpos = tdtl-acpos AND
                  newko = tdtl-newko AND
                  approved = 'X'.
        IF sy-subrc NE 0.
        ELSE.
          IF zsvctdtl-storn NE space.
            DELETE tdtl WHERE aufnr = tdtl-aufnr AND
                              seque = tdtl-seque AND
                              item  = tdtl-item.
            CONTINUE.
          ELSE.
            tdtl-wrbtr = zsvctdtl-wrbtrapr.
          ENDIF.
          MODIFY tdtl TRANSPORTING wrbtr WHERE aufnr = tdtl-aufnr AND
                                               seque = tdtl-seque AND
                                               item  = tdtl-item.
        ENDIF.
      ELSE.

      ENDIF.
    ENDIF.

  ENDLOOP.
* start insertion implementation IT/IS 626
** Get Actual Cost to be Transfer per WO
  LOOP AT list_wo.
    LOOP AT tdtl WHERE aufnr = list_wo-aufnr AND
                       newko = list_wo-hkont.
      list_wo-actual = list_wo-actual +  tdtl-wrbtr.
    ENDLOOP.
    LOOP AT wardel_bdg WHERE kostl = list_wo-kostl  AND
                            kstar = list_wo-hkont.
      list_wo-budget   = wardel_bdg-saldo.
      wardel_bdg-saldo = wardel_bdg-saldo - list_wo-actual.
      MODIFY wardel_bdg.
      CLEAR  wardel_bdg.
    ENDLOOP.
    list_wo-saldo = list_wo-budget - list_wo-actual.
    LOOP AT thdr WHERE aufnr = list_wo-aufnr.
      thdr-budget = list_wo-budget.
      thdr-saldo  = list_wo-saldo.
      WRITE thdr-budget TO thdr-bdgtxt CURRENCY thdr-waers. "#EC CI_FLDEXT_OK[2610650]
      WRITE thdr-saldo  TO thdr-saltxt CURRENCY thdr-waers. "#EC CI_FLDEXT_OK[2610650]
      IF list_wo-hkont EQ '7100000007'.
        IF thdr-saldo < 0.
          MOVE icon_defect TO thdr-indictr.
          thdr-posting = '1'.
        ENDIF.
      ENDIF.
      READ TABLE iaufk WITH KEY aufnr = thdr-aufnr.
      IF sy-subrc = 0.
        CALL FUNCTION 'ZFM_SVC_GET_SRD'
          EXPORTING
            e_vbeln = iaufk-kdauf
          CHANGING
            i_vbak  = ls_vbak
            i_vbap  = ls_vbap
            i_found = lv_found.
        IF lv_found = space.
        ELSE.
          IF ls_vbak-augru EQ 'PRT' OR
            ls_vbak-augru EQ 'MKT' OR
            ls_vbak-augru EQ 'GAD'." OR
*              ls_vbak-augru EQ 'SVC'.
            IF thdr-saldo < 0.
              MOVE icon_defect TO thdr-indictr.
              thdr-posting = '1'.
            ENDIF.
          ELSE.

          ENDIF.
        ENDIF.
      ENDIF.

      IF sy-batch = 'X' AND ( thdr-vaugru = 'PRT' OR thdr-auart = 'ZPRT' ) AND thdr-posting = '1'.
        PERFORM send_minus_email_pdh USING thdr-aufnr
                                            thdr-werks.
      ENDIF.

      MODIFY thdr.
      CLEAR  thdr.
    ENDLOOP.
    MODIFY list_wo.
    CLEAR  list_wo.
  ENDLOOP.

  IF s_hkont IS NOT INITIAL.                                "VTR 2516
    LOOP AT thdr.
      lv_del = ''.
      LOOP AT tdtl WHERE aufnr EQ thdr-aufnr
                     AND seque EQ thdr-seque
                     AND newbs EQ '40'.
        IF tdtl-newko NOT IN s_hkont.
          lv_del = 'X'.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_del EQ 'X'.
        DELETE tdtl WHERE aufnr EQ thdr-aufnr
                      AND seque EQ thdr-seque.
        DELETE thdr.
        CONTINUE.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF list EQ 'X'.
    LOOP AT thdr.
      WRITE:/ thdr-aufnr, thdr-seque, thdr-auart, thdr-bktxt,
              thdr-bldat, thdr-monat, thdr-uspart, thdr-vspart,
              thdr-vaugru, thdr-vaugru_d, thdr-ubstzd.
      LOOP AT tdtl WHERE aufnr EQ thdr-aufnr AND seque EQ thdr-seque.
        IF tdtl-newbs EQ '50'.
          tdtl-wrbtr = tdtl-wrbtr * -1.
        ENDIF.
        WRITE: /14 tdtl-newbs, tdtl-newko, tdtl-gsber, tdtl-order,
                   tdtl-kostl, tdtl-wrbtr CURRENCY tdtl-waers "#EC CI_FLDEXT_OK[2610650]
                   ,tdtl-zuonr, tdtl-sgtxt.
      ENDLOOP.
      SKIP.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " POSTING_DATA

*&---------------------------------------------------------------------*
*&      Form  POSTING_ZSSO
*&---------------------------------------------------------------------*
FORM posting_ziso.
  DATA: xhkont TYPE hkont,
        xvbak  TYPE vbak.
** Transfer JCS Produksi - JCS HO
*  LOOP AT DTL WHERE AUFNR EQ HDR-AUFNR.
*     CLEAR: TDTL.
*     MOVE-CORRESPONDING DTL TO TDTL.
*     TDTL-AUFNR = HDR-AUFNR.
*     TDTL-WAERS = HDR-WAERS.
*     TDTL-SEQUE = 1.
**    Debit
*     TDTL-NEWBS = '40'.
*     TDTL-NEWKO = HDR-NEWD1.
*     TDTL-GSBER = 'CMO'.
*     TDTL-ORDER = SPACE.
*     TDTL-KOSTL = 'SVCCMO_00'.
*     TDTL-ZUONR = SPACE.
*     APPEND TDTL.
**    Credit
*     TDTL-NEWBS = '50'.
*     TDTL-NEWKO = HDR-NEWC1.
*     TDTL-GSBER = HDR-GSBER.
*     TDTL-ORDER = HDR-AUFNR.
*     TDTL-KOSTL = SPACE.
*     TDTL-ZUONR = SPACE.
*     APPEND TDTL.
*  ENDLOOP.

** Transfer JCS HO - G/L Account Internal
*  CLEAR: ZHDR.
*  ZHDR = THDR. ZHDR-SEQUE = '2'. APPEND ZHDR.
*  LOOP AT DTL WHERE AUFNR EQ HDR-AUFNR.
*     CLEAR: TDTL.
*     MOVE-CORRESPONDING DTL TO TDTL.
*     TDTL-AUFNR = HDR-AUFNR.
*     TDTL-WAERS = HDR-WAERS.
*     TDTL-SEQUE = 2.
**    Debit
*     TDTL-NEWBS = '40'.
*     TDTL-NEWKO = HDR-NEWD2.
*     TDTL-GSBER = HDR-UGSKST.
*     TDTL-ORDER = SPACE.
*     TDTL-KOSTL = HDR-UKOSTL.
*     TDTL-ZUONR = HDR-AZUONR.
*     APPEND TDTL.
**    Credit
*     TDTL-NEWBS = '50'.
*     TDTL-NEWKO = HDR-NEWC2.
*     TDTL-GSBER = 'CMO'.
*     TDTL-ORDER = SPACE.
*     TDTL-KOSTL = 'SVCCMO_00'.
*     TDTL-ZUONR = SPACE.
*     APPEND TDTL.
*  ENDLOOP.

** Transfer COS - JCS Service
  LOOP AT dtl WHERE aufnr EQ hdr-aufnr.
    ADD 1 TO item.
    CLEAR: tdtl.
    MOVE-CORRESPONDING dtl TO tdtl.
    tdtl-aufnr = hdr-aufnr.
    tdtl-waers = hdr-waers.
    tdtl-seque = 1.
    tdtl-item = item + 1.
*    Debit
    tdtl-newbs = '40'.

    xhkont = hdr-newd2.
    CALL FUNCTION 'ZFM_SVC_GET_ORDER_SELLING'
      EXPORTING
        i_aufnr             = hdr-aufnr
        i_with_item         = space
      IMPORTING
        e_vbak              = xvbak
*       E_VBAP              =
      EXCEPTIONS
        wo_not_found        = 1
        order_sri_not_found = 2
        OTHERS              = 3.
    .
    IF sy-subrc = 0 AND NOT xvbak IS INITIAL.
      CALL FUNCTION 'ZFM_SVC_CHG_ALLOC_ACCOUNT'
        EXPORTING
          i_vbak     = xvbak
        CHANGING
          ch_account = xhkont.
      hdr-newd2  = xhkont.
      hdr-ahkont = xhkont.
      MODIFY hdr.
    ENDIF.
    tdtl-newko = hdr-newd2.
    tdtl-gsber = hdr-ugskst.
    tdtl-order = space.
    tdtl-kostl = hdr-ukostl.
*    Allocation.
    IF hdr-vaugru EQ 'MKT' OR hdr-vkunnr EQ 'BRANCH'.
      READ TABLE iaugru WITH KEY augru   = hdr-vaugru
                                 augru_d = hdr-vaugru_d
                                 kunag   = hdr-vkunnr.
      IF sy-subrc EQ 0.
        CASE tdtl-acpos.
          WHEN 'Z10'.
            tdtl-zuonr = iaugru-zuonr_p.
          WHEN 'Z20' OR 'Z32'.
            tdtl-zuonr = iaugru-zuonr_l.
          WHEN OTHERS.
            tdtl-zuonr = iaugru-zuonr_l.
        ENDCASE.
      ELSE.
        MESSAGE e398(00) WITH 'Error Allocation' ##NO_TEXT
            hdr-vaugru hdr-vaugru_d hdr-vkunnr.
      ENDIF.
    ELSE.
      READ TABLE iaugru WITH KEY augru   = hdr-vaugru
                                 augru_d = hdr-vaugru_d.
      IF sy-subrc EQ 0.
        CASE tdtl-acpos.
          WHEN 'Z10'.
            tdtl-zuonr = iaugru-zuonr_p.
          WHEN 'Z20' OR 'Z32'.
            tdtl-zuonr = iaugru-zuonr_l.
          WHEN OTHERS.
            tdtl-zuonr = iaugru-zuonr_l.
        ENDCASE.
      ELSE.
        MESSAGE e398(00) WITH 'Error Allocation' ##NO_TEXT
            hdr-vaugru hdr-vaugru_d ##MG_MISSING.
      ENDIF.
    ENDIF.
    APPEND tdtl.
*    Credit
    tdtl-newbs = '50'.
    tdtl-newko = hdr-newc1.
    tdtl-gsber = hdr-gsber.
    tdtl-order = hdr-aufnr.
    tdtl-kostl = space.
    tdtl-zuonr = space.
    APPEND tdtl.
  ENDLOOP.
ENDFORM.                    " POSTING_ZISO

*&---------------------------------------------------------------------*
*&      Form  POSTING_ZBSO
*&---------------------------------------------------------------------*
FORM posting_zbso.
** Transfer JCS Produksi - JCS HO
*  LOOP AT DTL WHERE AUFNR EQ HDR-AUFNR.
*     CLEAR: TDTL.
*     MOVE-CORRESPONDING DTL TO TDTL.
*     TDTL-AUFNR = HDR-AUFNR.
*     TDTL-WAERS = HDR-WAERS.
*     TDTL-SEQUE = 1.
**    Debit
*     TDTL-NEWBS = '40'.
*     TDTL-NEWKO = HDR-NEWD1.
*     TDTL-GSBER = 'CMO'.
*     TDTL-ORDER = SPACE.
*     TDTL-KOSTL = 'SVCCMO_00'.
*     APPEND TDTL.
**    Credit
*     TDTL-NEWBS = '50'.
*     TDTL-NEWKO = HDR-NEWC1.
*     TDTL-GSBER = HDR-GSBER.
*     TDTL-ORDER = HDR-AUFNR.
*     TDTL-KOSTL = SPACE.
*     APPEND TDTL.
*  ENDLOOP.

* Transfer JCS HO - JCS Transaksi
*  CLEAR: ZHDR.
*  ZHDR = THDR. ZHDR-SEQUE = '2'. APPEND ZHDR.
*  LOOP AT DTL WHERE AUFNR EQ HDR-AUFNR.
*     CLEAR: TDTL.
*     MOVE-CORRESPONDING DTL TO TDTL.
*     TDTL-AUFNR = HDR-AUFNR.
*     TDTL-WAERS = HDR-WAERS.
*     TDTL-SEQUE = 2.
**    Debit
*     TDTL-NEWBS = '40'.
*     TDTL-NEWKO = HDR-NEWD2.
*     TDTL-GSBER = HDR-LGSBER.
*     TDTL-ORDER = HDR-LAUFNR.
*     TDTL-KOSTL = SPACE.
*     APPEND TDTL.
**    Credit
*     TDTL-NEWBS = '50'.
*     TDTL-NEWKO = HDR-NEWC2.
*     TDTL-GSBER = 'CMO'.
*     TDTL-ORDER = SPACE.
*     TDTL-KOSTL = 'SVCCMO_00'.
*     APPEND TDTL.
*  ENDLOOP.

* Transfer to JCS Produksi - JCS Transaksi
  LOOP AT dtl WHERE aufnr EQ hdr-aufnr.
    ADD 1 TO item.
    CLEAR: tdtl.
    MOVE-CORRESPONDING dtl TO tdtl.
    tdtl-aufnr = hdr-aufnr.
    tdtl-waers = hdr-waers.
    tdtl-seque = 1.
    tdtl-item = item + 1.
*    Debit
    tdtl-newbs = '40'.
    tdtl-newko = hdr-newd2.
    tdtl-gsber = hdr-lgsber.
    tdtl-order = hdr-laufnr.
    tdtl-kostl = space.
    APPEND tdtl.
*    Credit
    tdtl-newbs = '50'.
    tdtl-newko = hdr-newc1.
    tdtl-gsber = hdr-gsber.
    tdtl-order = hdr-aufnr.
    tdtl-kostl = space.
    APPEND tdtl.
  ENDLOOP.
ENDFORM.                    " POSTING_ZBSO

*&---------------------------------------------------------------------*
*&      Form  POSTING_ZPTS
*&---------------------------------------------------------------------*
FORM posting_zpts.
* Transfer PTS Produksi - PTS Transaksi
  LOOP AT dtl WHERE aufnr EQ hdr-aufnr.
    ADD 1 TO item.
    CLEAR: tdtl.
    MOVE-CORRESPONDING dtl TO tdtl.
    tdtl-aufnr = hdr-aufnr.
    tdtl-waers = hdr-waers.
    tdtl-seque = 1.
    tdtl-item = item + 1.
**    Debit
    tdtl-newbs = '40'.
    tdtl-newko = hdr-newd2.
    tdtl-gsber = hdr-tgsber.
    tdtl-order = hdr-taufnr.
    APPEND tdtl.
*    Credit
    tdtl-newbs = '50'.
    tdtl-newko = hdr-newc2.
    tdtl-gsber = hdr-gsber.
    tdtl-order = hdr-aufnr.
    APPEND tdtl.
  ENDLOOP.
ENDFORM.                    " POSTING_ZPTS

*&---------------------------------------------------------------------*
*&      Form  POSTING_ZPRT
*&---------------------------------------------------------------------*
FORM posting_zprt.
* Transfer COS Parts Others - JCS Service
  LOOP AT dtl WHERE aufnr EQ hdr-aufnr.
    ADD 1 TO item.
    CLEAR: tdtl.
    tdtl-aufnr = hdr-aufnr.
    tdtl-waers = hdr-waers.
    tdtl-wrbtr = dtl-wrbtr.
    tdtl-acpos = dtl-acpos.
    tdtl-zuonr = 'CP04'.
    tdtl-seque = 1.
    tdtl-item = item + 1.
*    Debit
    tdtl-newbs = '40'.
    tdtl-newko = hdr-newd1.
    tdtl-gsber = hdr-gsber.
    CONCATENATE '01' hdr-gsber INTO tdtl-kostl.
    tdtl-sgtxt  = dtl-sgtxt.
    APPEND tdtl.
*    Credit
    tdtl-newbs = '50'.
    tdtl-newko = hdr-newc1.
    tdtl-order = hdr-aufnr.
    tdtl-gsber = hdr-gsber.
    tdtl-kostl = dtl-kostl.
    APPEND tdtl.
  ENDLOOP.
ENDFORM.                    " POSTING_ZPRT


*&---------------------------------------------------------------------*
*&      Form  POSTING_BATCH
*&---------------------------------------------------------------------*
FORM posting_batch.
  REFRESH: bdcdata.
  CLEAR: bdcdata, item.
  WRITE: sy-datum TO datum,
         p_bldat TO tbldat,
         p_budat TO tbudat.
  IF backg EQ 'X'.
    PERFORM open_group.
  ENDIF.
  DESCRIBE TABLE thdr LINES baris.
  LOOP AT thdr WHERE posting = '0'.
    ADD 1 TO no.
    WRITE: no TO tno, baris TO tbrs.
    IF test IS INITIAL.
      CONCATENATE 'Update PMIS Order no' ##NO_TEXT thdr-aufnr tno 'TO' ##NO_TEXT tbrs
          INTO txt SEPARATED BY space.
    ELSE.
      CONCATENATE tno 'to' tbrs 'Order no' thdr-aufnr INTO txt
       SEPARATED BY space ##NO_TEXT ##NO_TEXT.
    ENDIF.
    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR' ##FM_SUBRC_OK
      EXPORTING
*       PERCENTAGE = 0
        text   = txt
      EXCEPTIONS
        OTHERS = 1.

    REFRESH: bdcdata.
    CLEAR: bdcdata, item, xblnr.
    WRITE thdr-aufnr TO xblnr NO-ZERO.
    PERFORM bdc_dynpro      USING 'SAPMF05A' '0100'.
    PERFORM bdc_field       USING 'BKPF-BLDAT' tbldat.
    PERFORM bdc_field       USING 'BKPF-BLART' thdr-blart.
    PERFORM bdc_field       USING 'BKPF-BUKRS' thdr-bukrs.
    PERFORM bdc_field       USING 'BKPF-BUDAT' tbudat.
    PERFORM bdc_field       USING 'BKPF-MONAT' thdr-monat.
    PERFORM bdc_field       USING 'BKPF-WAERS' thdr-waers.
*     PERFORM BDC_FIELD       USING 'BKPF-XBLNR' XBLNR.  "thdr-aufnr.
    PERFORM bdc_field       USING 'BKPF-XBLNR' thdr-aufnr.
    PERFORM bdc_field       USING 'BKPF-BKTXT' thdr-bktxt.

    LOOP AT tdtl WHERE aufnr EQ thdr-aufnr AND seque EQ thdr-seque.
      IF tdtl-wrbtr LT 0.
        tdtl-wrbtr = tdtl-wrbtr * -1.
      ENDIF.
      WRITE: tdtl-wrbtr TO xwrbtr CURRENCY tdtl-waers. "#EC CI_FLDEXT_OK[2610650]
      ADD 1 TO item.
      IF item EQ 1.
        PERFORM bdc_field       USING 'RF05A-NEWBS' tdtl-newbs.
        PERFORM bdc_field       USING 'RF05A-NEWKO' tdtl-newko.
        PERFORM bdc_field       USING 'BDC_OKCODE' '/00'.
      ELSE.
        PERFORM bdc_dynpro      USING 'SAPMF05A' '0700'.
        PERFORM bdc_field       USING 'RF05A-NEWBS' tdtl-newbs.
        PERFORM bdc_field       USING 'RF05A-NEWKO' tdtl-newko.
        PERFORM bdc_field       USING 'BDC_OKCODE' '/00'.
      ENDIF.
      PERFORM bdc_dynpro      USING 'SAPMF05A' '0300'.
      PERFORM bdc_field       USING 'BSEG-WRBTR' xwrbtr.
      PERFORM bdc_field       USING 'BSEG-ZUONR' tdtl-zuonr.
      PERFORM bdc_field       USING 'BSEG-SGTXT' tdtl-sgtxt.
      PERFORM bdc_field       USING 'BDC_OKCODE' '=AB'.

      PERFORM bdc_dynpro      USING 'SAPLKACB' '0002'.
      PERFORM bdc_field       USING 'COBL-GSBER' tdtl-gsber.
      IF NOT tdtl-kostl IS INITIAL.
        PERFORM bdc_field    USING 'COBL-KOSTL' tdtl-kostl.
      ENDIF.
      IF NOT tdtl-order IS INITIAL.
        PERFORM bdc_field    USING 'COBL-AUFNR' tdtl-order.
      ENDIF.
      PERFORM bdc_field       USING 'BDC_OKCODE' '=ENTE'.
    ENDLOOP.
    PERFORM bdc_dynpro      USING 'SAPMF05A' '0700'.
    IF test EQ 'X'.
      PERFORM bdc_field       USING 'BDC_OKCODE' '=BS'.
      CLEAR: backg.
      PERFORM bdc_dynpro      USING 'SAPMF05A' '0700'.
      PERFORM bdc_field       USING 'BDC_OKCODE' '=RW'.
      PERFORM bdc_dynpro      USING 'SAPLSPO1' '0200'.
      PERFORM bdc_field       USING 'BDC_OKCODE' '=YES'.
    ELSE.
      PERFORM bdc_field       USING 'BDC_OKCODE' '=BU'.
    ENDIF.
    IF backg EQ 'X'.
      PERFORM bdc_transaction USING 'F-02'.
    ELSE.
      CALL TRANSACTION 'F-02' USING bdcdata MODE xmode UPDATE 'S'.
    ENDIF.
  ENDLOOP.
  IF backg EQ 'X'.
    PERFORM close_group.
    SUBMIT rsbdcsub AND RETURN
                    USER sy-uname
                    WITH mappe    =  group
                    WITH von      =  sy-datum
                    WITH bis      =  sy-datum
                    WITH logall   =  'X'
                    WITH z_verarb =  'X'.
  ENDIF.
ENDFORM.                    " POSTING_BATCH

*&---------------------------------------------------------------------*
*&      Form  BDC_DYNPRO
*&---------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.
  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.                    " BDC_DYNPRO

*&---------------------------------------------------------------------*
*&      Form  BDC_FIELD
*&---------------------------------------------------------------------*
FORM bdc_field USING fnam fval.
  CLEAR bdcdata.
  bdcdata-fnam = fnam.
  bdcdata-fval = fval.
  APPEND bdcdata.
ENDFORM.                    " BDC_FIELD

*&---------------------------------------------------------------------*
*&      form  bdc_transaction
*&---------------------------------------------------------------------*
FORM bdc_transaction USING    tcode.
  CALL FUNCTION 'BDC_INSERT'
    EXPORTING
      tcode     = tcode
    TABLES
      dynprotab = bdcdata.
ENDFORM.                    " BDC_TRANSACTION
*&---------------------------------------------------------------------*
*&      Form  OPEN_GROUP
*&---------------------------------------------------------------------*
FORM open_group.
  DATA: group    LIKE apqi-groupid,
        holddate LIKE sy-datum.

  CONCATENATE 'STRC' sy-datum INTO group.
  CALL FUNCTION 'BDC_OPEN_GROUP'
    EXPORTING
      client   = sy-mandt
      group    = group
      user     = sy-uname
      keep     = 'X'
      holddate = holddate.
ENDFORM.                    " OPEN_GROUP
*&---------------------------------------------------------------------*
*&      Form  CLOSE_GROUP
*&---------------------------------------------------------------------*
FORM close_group.
  CALL FUNCTION 'BDC_CLOSE_GROUP'.
ENDFORM.                    " CLOSE_GROUP

*&---------------------------------------------------------------------*
*&      Form  INITIALIZATION_DATA
*&---------------------------------------------------------------------*
FORM initialization_data.
  REFRESH: r_aufart.
  r_aufart-sign = 'I'. r_aufart-option = 'EQ'.
  v_auart = 'ZISOZSCHZYRDZBSOZPRTZPTSZIPKZSVCZRNT'.
  DO 9 TIMES.
    r_aufart-low = v_auart(4).
    APPEND r_aufart.
    SHIFT v_auart BY 4 PLACES.
  ENDDO.

* Value Category
  SELECT * INTO TABLE iacpos FROM tpir1t WHERE langu EQ sy-langu.
* Cost Determination
  SELECT * INTO TABLE itvauk FROM tvauk WHERE vkorg EQ 'CMSO'.
  SORT itvauk BY vkorg vtweg augru spart datab DESCENDING.
  DELETE ADJACENT DUPLICATES FROM itvauk
    COMPARING vkorg vtweg spart augru.
* Alokasi Pembebanan
  SELECT * INTO TABLE iaugru FROM zaugru.
* Service Order type
  SELECT * INTO TABLE i003o FROM t003o WHERE autyp EQ '30'
     AND auart IN r_aufart.

* ALV
  g_repid           = sy-repid.
  CLEAR keyinfo.
  keyinfo-header01 = 'AUFNR'.
  keyinfo-item01   = 'AUFNR'.

ENDFORM.                    " INITIALIZATION_DATA

*&---------------------------------------------------------------------*
*&      Form  READ_ACPOS
*&---------------------------------------------------------------------*
FORM read_acpos USING p_acpos CHANGING p_sgtxt.
  READ TABLE iacpos WITH KEY acpos = p_acpos.
  IF sy-subrc EQ 0.
*     CONCATENATE P_ACPOS IACPOS-KTEXT INTO P_SGTXT SEPARATED BY ':'.
    p_sgtxt = p_acpos.
  ELSE.
    p_sgtxt = 'Not Assigned' ##NO_TEXT.
  ENDIF.
ENDFORM.                    " READ_ACPOS

*&---------------------------------------------------------------------*
*&      Form  CAUFV_READ
*&---------------------------------------------------------------------*
FORM caufv_read USING p_aufnr
             CHANGING p_lauart p_lwerks p_lgsber.
  SELECT SINGLE * FROM caufv WHERE aufnr EQ p_aufnr.
  IF sy-subrc EQ 0.
    MOVE: caufv-auart TO p_lauart,
          caufv-werks TO p_lwerks,
          caufv-gsber TO p_lgsber.
  ENDIF.
ENDFORM.                    " CAUFV_READ
*&---------------------------------------------------------------------*
*&      Form  INSERT_ERROR
*&---------------------------------------------------------------------*
FORM insert_error USING p_ecode p_aufnr p_sgtxt.
  CLEAR: erlist.
  CASE p_ecode.
    WHEN '1'. erlist-ertxt = TEXT-501 ##TEXT_POOL.
    WHEN '2'. erlist-ertxt = TEXT-502 ##TEXT_POOL.
    WHEN '3'. erlist-ertxt = TEXT-503 ##TEXT_POOL.
    WHEN '4'. erlist-ertxt = TEXT-504 ##TEXT_POOL.
    WHEN '5'. erlist-ertxt = TEXT-505 ##TEXT_POOL.
    WHEN '6'. erlist-ertxt = TEXT-506 ##TEXT_POOL.
  ENDCASE.
  erlist-ecode = p_ecode.
  erlist-aufnr = p_aufnr.
  erlist-sgtxt = p_sgtxt.
  APPEND erlist.
ENDFORM.                    " INSERT_ERROR

*&---------------------------------------------------------------------*
*&      Form  INIT_FIELD
*&---------------------------------------------------------------------*
FORM init_field.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_internal_tabname = 'THDR'
      i_structure_name   = 'AUFK'
    CHANGING
      ct_fieldcat        = fieldcat2.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_internal_tabname = 'THDR'
      i_structure_name   = 'BKPF'
    CHANGING
      ct_fieldcat        = fieldcat2.
  CLEAR: colpos.


  fieldcat_ln-tabname     = 'THDR'.
  fieldcat_ln-ref_tabname = 'VBAK'.

  ADD 1 TO colpos.
  fieldcat_ln-col_pos = colpos.
  fieldcat_ln-fieldname     = 'INDICTR' ##NO_TEXT.
  fieldcat_ln-key           = 'X' ##NO_TEXT.
  fieldcat_ln-seltext_l     = 'Stat' ##NO_TEXT.
  fieldcat_ln-seltext_s     = 'Stat' ##NO_TEXT.
  fieldcat_ln-outputlen     = 4.
  APPEND fieldcat_ln TO fieldcat.

  ADD 1 TO colpos.
  fieldcat_ln-col_pos = colpos.
  fieldcat_ln-fieldname     = 'BDGTXT' ##NO_TEXT.
  fieldcat_ln-key           = 'X' ##NO_TEXT.
*  FIELDCAT_LN-cfieldname    = 'WAERS' ##NO_TEXT.
  fieldcat_ln-seltext_l     = '        Budget' ##NO_TEXT.
  fieldcat_ln-seltext_s     = '        Budget' ##NO_TEXT.
  fieldcat_ln-outputlen     = 15.
  APPEND fieldcat_ln TO fieldcat.

  ADD 1 TO colpos.
  fieldcat_ln-col_pos = colpos.
  fieldcat_ln-fieldname     = 'SALTXT'.
  fieldcat_ln-key           = 'X'.
*  FIELDCAT_LN-cfieldname    = 'WAERS'.
  fieldcat_ln-seltext_l     = '        Saldo' ##NO_TEXT.
  fieldcat_ln-seltext_s     = '        Saldo' ##NO_TEXT.
  fieldcat_ln-outputlen     = 15.
  APPEND fieldcat_ln TO fieldcat.

  LOOP AT fieldcat2 INTO fieldcat_ln.
    CHECK 'AUFNRAUARTBUKRSBLARTBUDATBLDATMONATXBLNRBKTXT'
          CS fieldcat_ln-fieldname.
    ADD 1 TO colpos. fieldcat_ln-col_pos = colpos.
    fieldcat_ln-no_out = space.
    APPEND fieldcat_ln TO fieldcat.
  ENDLOOP.

  CLEAR: fieldcat_ln.

  REFRESH: fieldcat2.

  fieldcat_ln-tabname     = 'THDR'.
  fieldcat_ln-ref_tabname = 'VBAK'.

  ADD 1 TO fieldcat_ln-col_pos.
  fieldcat_ln-fieldname     = 'USPART'.
  fieldcat_ln-ref_fieldname = 'SPART'.
  APPEND fieldcat_ln TO fieldcat.

  ADD 1 TO fieldcat_ln-col_pos.
  fieldcat_ln-fieldname     = 'VSPART'.
  fieldcat_ln-ref_fieldname = 'SPART'.
  APPEND fieldcat_ln TO fieldcat.

  ADD 1 TO fieldcat_ln-col_pos.
  fieldcat_ln-fieldname     = 'VAUGRU'.
  fieldcat_ln-ref_fieldname = 'AUGRU'.
  APPEND fieldcat_ln TO fieldcat.

  ADD 1 TO fieldcat_ln-col_pos.
  fieldcat_ln-fieldname     = 'VAUGRU_D'.
  fieldcat_ln-ref_fieldname = 'AUGRU'.
  APPEND fieldcat_ln TO fieldcat.

  ADD 1 TO fieldcat_ln-col_pos.
  fieldcat_ln-fieldname     = 'UBSTZD'.
  fieldcat_ln-ref_fieldname = 'BSTZD'.
  APPEND fieldcat_ln TO fieldcat.

  ADD 1 TO fieldcat_ln-col_pos.
  fieldcat_ln-fieldname     = 'VKUNNR'.
  fieldcat_ln-ref_fieldname = 'KUNNR'.
  APPEND fieldcat_ln TO fieldcat.

  SORT fieldcat BY col_pos ASCENDING.

  fieldcat_ln-tabname     = 'TDTL'.
  fieldcat_ln-ref_tabname = 'AUFK'.

  ADD 1 TO fieldcat_ln-col_pos.
  fieldcat_ln-fieldname = fieldcat_ln-ref_fieldname   = 'AUFNR'.
  fieldcat_ln-no_out = 'X'.
  APPEND fieldcat_ln TO fieldcat.
  colpos = fieldcat_ln-col_pos.

  ADD 1 TO fieldcat_ln-col_pos.
  fieldcat_ln-fieldname = 'ITEM'.
  fieldcat_ln-ref_tabname = 'SYST'.
  fieldcat_ln-ref_fieldname = 'TABIX'.
  APPEND fieldcat_ln TO fieldcat.
  colpos = fieldcat_ln-col_pos.
  CLEAR: fieldcat_ln.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_internal_tabname = 'TDTL'
      i_structure_name   = 'RF05A'
    CHANGING
      ct_fieldcat        = fieldcat2.
  LOOP AT fieldcat2 INTO fieldcat_ln.
    CHECK 'NEWBSNEWKO' CS fieldcat_ln-fieldname.
    ADD 1 TO colpos. fieldcat_ln-col_pos = colpos.
    fieldcat_ln-no_out = space.
    APPEND fieldcat_ln TO fieldcat.
  ENDLOOP.

  REFRESH: fieldcat2.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_internal_tabname = 'TDTL'
      i_structure_name   = 'BSEG'
    CHANGING
      ct_fieldcat        = fieldcat2.
  colpos = 20.
  LOOP AT fieldcat2 INTO fieldcat_ln.
    CHECK 'AUFNRWRBTRWAERSGSBERKOSTLZUONRSGTXT'
          CS fieldcat_ln-fieldname.
    CASE fieldcat_ln-fieldname.
      WHEN 'GSBER'. colpos = 21.
      WHEN 'AUFNR'. colpos = 22.
      WHEN 'KOSTL'. colpos = 23.
      WHEN 'WRBTR'. colpos = 24.
      WHEN 'ZUONR'. colpos = 25.
      WHEN 'SGTXT'. colpos = 26.
    ENDCASE.
    fieldcat_ln-col_pos = colpos.
    fieldcat_ln-no_out = space.
    IF fieldcat_ln-fieldname EQ 'AUFNR'.
      fieldcat_ln-fieldname = 'ORDER'.
      fieldcat_ln-ref_fieldname = 'AUFNR'.
    ENDIF.
    IF fieldcat_ln-fieldname EQ 'WRBTR'.
      fieldcat_ln-cfieldname = 'WAERS'.
    ENDIF.
    IF fieldcat_ln-fieldname EQ 'SGTXT'.
      fieldcat_ln-outputlen = '5'.
    ENDIF.
    APPEND fieldcat_ln TO fieldcat.
  ENDLOOP.
  fieldcat_ln-fieldname = 'WAERS'.
  fieldcat_ln-ref_tabname = 'BKPF'.
  fieldcat_ln-ref_fieldname = 'WAERS'.
  APPEND fieldcat_ln TO fieldcat.

ENDFORM.                    " INIT_FIELD

*&---------------------------------------------------------------------*
*&      Form  INIT_EVENT
*&---------------------------------------------------------------------*
FORM init_event.
  eventcat_ln-name = 'TOP_OF_PAGE'.
  eventcat_ln-form = 'PAGE_HEADER'.
  APPEND eventcat_ln TO eventcat.
ENDFORM.                    " INIT_EVENT

*&---------------------------------------------------------------------*
*&      Form  INIT_SORT
*&---------------------------------------------------------------------*
FORM init_sort.
  sortcat_ln-spos = '1'.
  sortcat_ln-tabname   = 'THDR'.
  sortcat_ln-fieldname = 'AUFNR'.
  sortcat_ln-up        = 'X'.
  APPEND sortcat_ln TO sortcat.

  sortcat_ln-spos = '2'.
  sortcat_ln-tabname   = 'TDTL'.
  sortcat_ln-fieldname = 'AUFNR'.
  sortcat_ln-up        = 'X'.
  APPEND sortcat_ln TO sortcat.

  sortcat_ln-spos = '3'.
  sortcat_ln-tabname   = 'TDTL'.
  sortcat_ln-fieldname = 'NEWBS'.
  sortcat_ln-up        = 'X'.
  APPEND sortcat_ln TO sortcat.

  sortcat_ln-spos = '4'.
  sortcat_ln-tabname   = 'TDTL'.
  sortcat_ln-fieldname = 'ITEM'.
  sortcat_ln-up        = 'X'.
  APPEND sortcat_ln TO sortcat.

ENDFORM.                    " INIT_SORT

*&---------------------------------------------------------------------*
*&      Form  INIT_LAYOUT
*&---------------------------------------------------------------------*
FORM init_layout USING ls_layout TYPE slis_layout_alv.
  p_chkbox  = space.
  ls_layout-zebra             = 'X'.

  IF p_chkbox = 'X'.
    ls_layout-box_fieldname     = g_boxnam.
    ls_layout-box_tabname       = g_tabname_item.
  ELSE.
    CLEAR ls_layout-box_fieldname.
    CLEAR ls_layout-box_tabname.
  ENDIF.
ENDFORM.                    " INIT_LAYOUT
*&---------------------------------------------------------------------*
*&      Form  ALV_LIST
*&---------------------------------------------------------------------*
FORM alv_list.
  g_repid = sy-repid.
  CALL FUNCTION 'REUSE_ALV_HIERSEQ_LIST_DISPLAY' ##FM_SUBRC_OK
    EXPORTING
      i_callback_program       = g_repid
      i_callback_pf_status_set = g_status
      i_callback_user_command  = g_ucomm
      is_layout                = layout
      it_fieldcat              = fieldcat
      it_sort                  = sortcat[]
      i_default                = g_default
      it_events                = eventcat
      i_tabname_header         = 'THDR'
      i_tabname_item           = 'TDTL'
      is_keyinfo               = keyinfo
    TABLES
      t_outtab_header          = thdr
      t_outtab_item            = tdtl
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

ENDFORM.                    " ALV_LIST

*&---------------------------------------------------------------------*
*&      Form  PAGE_HEADER
*&---------------------------------------------------------------------*
FORM page_header.
  WRITE:/ 'Header' ##NO_TEXT.
ENDFORM.                    " PAGE_HEADER
*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_command USING ucomm LIKE sy-ucomm
                        selfield TYPE slis_selfield.
  v_ucomm = ucomm.
  CASE selfield-tabname.
    WHEN 'THDR'.
      READ TABLE thdr INDEX selfield-tabindex.
    WHEN 'TDTL'.
      READ TABLE tdtl INDEX selfield-tabindex.
  ENDCASE.
  CHECK sy-subrc EQ 0.
  CASE ucomm.
    WHEN '&IC1'.
      CASE selfield-sel_tab_field.
        WHEN 'TDTL-AUFNR'.
          CHECK tdtl-aufnr NE space.
          SET PARAMETER ID 'AUN' FIELD tdtl-aufnr.
          CALL TRANSACTION 'IW33' AND SKIP FIRST SCREEN.
      ENDCASE.
  ENDCASE.
ENDFORM.                    " USER_COMMAND
*&---------------------------------------------------------------------*
*&      Form  CHECK_ENTRY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_entry.
  IF sy-uname EQ 'SVCIS'.
    IF p_werks-low EQ 'BJM' OR p_werks-high EQ 'BJM'.
      MESSAGE i398(00) WITH 'Lampit...Lampit....Lampit....' ##MG_MISSING.
    ENDIF.
  ENDIF.
ENDFORM.                    " CHECK_ENTRY

*&---------------------------------------------------------------------*
*&      Form  POSTING_ZIPK
*&---------------------------------------------------------------------*
FORM posting_zipk.

** Transfer COS - JCS Service REMAN
  LOOP AT dtl WHERE aufnr EQ hdr-aufnr .
**           and ( acpos EQ 'Z20' or acpos EQ 'Z32' ).
    ADD 1 TO item.
    CLEAR: tdtl.

    MOVE-CORRESPONDING dtl TO tdtl.
    tdtl-aufnr = hdr-aufnr.
    tdtl-waers = hdr-waers.
    tdtl-seque = 1.
    tdtl-item = item + 1.
*    Debit
    tdtl-newbs = '40'.
    tdtl-newko = hdr-newd2.


    tdtl-gsber = hdr-ugskst.

*    tdtl-order = hdr-aufnr.
    tdtl-kostl = hdr-ukostl.
*    tdtl-order = space.
*    tdtl-kostl = hdr-ukostl.
*    Allocation.
    IF hdr-vaugru EQ 'MKT' OR hdr-vkunnr EQ 'BRANCH'.
      READ TABLE iaugru WITH KEY augru   = hdr-vaugru
                                 augru_d = hdr-vaugru_d
                                 kunag   = hdr-vkunnr.
      IF sy-subrc EQ 0.
        CASE tdtl-acpos.
          WHEN 'Z43'.
*            PERFORM get_po_gl.
*            CHECK gl_sakto EQ '6562000010'.
            tdtl-zuonr = iaugru-zuonr_p.
          WHEN 'Z20' OR 'Z32' OR 'Z44'." OR 'Z10' OR 'Z41'.
            tdtl-zuonr = iaugru-zuonr_l.
          WHEN OTHERS.
            IF hdr-auart NE 'ZIPK'.
              CONTINUE.
            ENDIF.
        ENDCASE.
      ELSE.
        MESSAGE e398(00) WITH 'Error Allocation' ##NO_TEXT
            hdr-vaugru hdr-vaugru_d hdr-vkunnr.
      ENDIF.
    ELSE.
      READ TABLE iaugru WITH KEY augru   = hdr-vaugru
                                 augru_d = hdr-vaugru_d.
      IF sy-subrc EQ 0.
        CASE tdtl-acpos.
          WHEN 'Z43'.
            PERFORM get_po_gl.
            CHECK gl_sakto EQ '6562000010'.
            tdtl-zuonr = iaugru-zuonr_p.
          WHEN 'Z20' OR 'Z32' OR 'Z44' OR 'Z10' OR 'Z41'.
            tdtl-zuonr = iaugru-zuonr_l.
          WHEN OTHERS.
            CONTINUE.
        ENDCASE.
      ELSE.
        MESSAGE e398(00) WITH 'Error Allocation' ##NO_TEXT
            hdr-vaugru hdr-vaugru_d ##MG_MISSING.
      ENDIF.
    ENDIF.
    APPEND tdtl.
*    Credit
    tdtl-newbs = '50'.
    tdtl-newko = hdr-newc1.
    tdtl-gsber = hdr-gsber.
    tdtl-order = hdr-aufnr.
    tdtl-kostl = space.
    tdtl-zuonr = space.
    CASE tdtl-acpos.
      WHEN 'Z20' OR 'Z32' OR 'Z44' OR 'Z43'.
        tdtl-newko = '6562000005'.
    ENDCASE.
    APPEND tdtl.
  ENDLOOP.

ENDFORM.                    " POSTING_ZIPK

*&---------------------------------------------------------------------*
*&      Form  AUART_ZIPK
*&---------------------------------------------------------------------*
FORM auart_zipk.
  DATA: lv_gl TYPE ska1-saknr.
  IF hdr-vauart EQ 'ZSRI'.
    "PERFORM get_gl_based_costelement USING hdr-objnr CHANGING lv_gl.
    lv_gl = '6562000055'.
    hdr-newd1 = lv_gl."'6562000005'.      "Cost Service JCS
    hdr-newc1 = lv_gl."'6562000005'.      "Cost Service JCS
*    IF hdr-vaugru = 'RDO'.
*      hdr-newd2 = '6562000058'.   "Cost Pekerjaan Ulang Reman
*    ELSE.
    hdr-newd2 = hdr-ahkont.        "Cost by order reason
*    ENDIF.
    hdr-newc2 = lv_gl."'6562000005'.      "Cost Service JCS
  ELSE.
    hdr-delet = 'X'.
  ENDIF.

ENDFORM.                    " AUART_ZIPK
*&---------------------------------------------------------------------*
*&      Form  AUART_ZRNT
*&---------------------------------------------------------------------*
FORM auart_zrnt.
  DATA: lv_gl TYPE ska1-saknr.
  IF hdr-vauart EQ 'ZCRN'.
    PERFORM get_gl_based_costelement USING hdr-objnr CHANGING lv_gl.
    hdr-newd1 = lv_gl."'6562000005'.      "Cost Service JCS
    hdr-newc1 = lv_gl."'6562000005'.      "Cost Service JCS
    hdr-newd2 = hdr-ahkont.        "Cost by order reason
    hdr-newc2 = lv_gl."'6562000005'.      "Cost Service JCS
  ELSE.
    hdr-delet = 'X'.
  ENDIF.

ENDFORM.                    " AUART_ZIPK
*&---------------------------------------------------------------------*
*&      Form  POSTING_ZRNT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM posting_zrnt .
** Transfer COS - JCS Service
  LOOP AT dtl WHERE aufnr EQ hdr-aufnr.
    ADD 1 TO item.
    CLEAR: tdtl.
    MOVE-CORRESPONDING dtl TO tdtl.
    tdtl-aufnr = hdr-aufnr.
    tdtl-waers = hdr-waers.
    tdtl-seque = 1.
    tdtl-item = item + 1.
*    Debit
    tdtl-newbs = '40'.
    tdtl-newko = hdr-newd2.
    tdtl-gsber = hdr-ugskst.
    tdtl-order = hdr-aufnr.
    tdtl-kostl = space.
*    tdtl-order = space.
*    tdtl-kostl = hdr-ukostl.
*    Allocation.
    IF hdr-vaugru EQ 'MKT' OR hdr-vkunnr EQ 'BRANCH'.
      READ TABLE iaugru WITH KEY augru   = hdr-vaugru
                                 augru_d = hdr-vaugru_d
                                 kunag   = hdr-vkunnr.
      IF sy-subrc EQ 0.
        CASE tdtl-acpos.
          WHEN 'Z43'.
            PERFORM get_po_gl.
            CHECK gl_sakto EQ '6562000010'.
            tdtl-zuonr = iaugru-zuonr_p.
          WHEN 'Z20' OR 'Z32' OR 'Z44'.
            tdtl-zuonr = iaugru-zuonr_l.
          WHEN OTHERS.
            CONTINUE.
        ENDCASE.
      ELSE.
        MESSAGE e398(00) WITH 'Error Allocation' ##NO_TEXT
            hdr-vaugru hdr-vaugru_d hdr-vkunnr.
      ENDIF.
    ELSE.
      READ TABLE iaugru WITH KEY augru   = hdr-vaugru.
*                                 augru_d = hdr-vaugru_d.  ITIS 10703
      IF sy-subrc EQ 0.
        CASE tdtl-acpos.
          WHEN 'Z43'.
            PERFORM get_po_gl.
            CHECK gl_sakto EQ '6562000010'.
            tdtl-zuonr = iaugru-zuonr_p.
          WHEN 'Z20' OR 'Z32' OR 'Z44'.
            tdtl-zuonr = iaugru-zuonr_l.
          WHEN OTHERS.
            CONTINUE.
        ENDCASE.
      ELSE.
        MESSAGE e398(00) WITH 'Error Allocation' ##NO_TEXT
            hdr-vaugru hdr-vaugru_d ##MG_MISSING.
      ENDIF.
    ENDIF.
    APPEND tdtl.
*    Credit
    tdtl-newbs = '50'.
    tdtl-newko = hdr-newc1.
    tdtl-gsber = hdr-gsber.
    tdtl-order = hdr-aufnr.
    tdtl-kostl = space.
    tdtl-zuonr = space.
    APPEND tdtl.
  ENDLOOP.
ENDFORM.                    " POSTING_ZRNT
*&---------------------------------------------------------------------*
*&      Form  GET_PO_GL
*&---------------------------------------------------------------------*
FORM get_po_gl .

  CLEAR gl_sakto.
  SELECT SINGLE sakto INTO gl_sakto
    FROM ekkn WHERE aufnr EQ tdtl-aufnr.

ENDFORM.                    " GET_PO_GL
*&---------------------------------------------------------------------*
*&      Form  GET_GL_BASED_COSTELEMENT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_OBJNR  text
*      <--P_GL  text
*----------------------------------------------------------------------*
FORM get_gl_based_costelement  USING    p_objnr TYPE aufk-objnr
                               CHANGING p_gl.
  DATA: lt_cosp_aufk TYPE TABLE OF v_cosp_view,
        ls_cosp_aufk TYPE v_cosp_view.
  SELECT * FROM v_coss_view APPENDING CORRESPONDING FIELDS OF TABLE @lt_cosp_aufk
      WHERE lednr EQ '00'
       AND  objnr EQ @p_objnr
       AND  wrttp EQ '04'
       AND  versn EQ '000'  "001 = master plan  000 = active plan
       AND  perbl EQ '016'
       AND beknz EQ 'S'.

  LOOP AT lt_cosp_aufk INTO ls_cosp_aufk.
    IF ls_cosp_aufk-kstar(7) = 'SVC-LBR'.
      p_gl = '6562000005'.
    ENDIF.
    IF ls_cosp_aufk-kstar(7) = 'FMC-LBR'.
      p_gl = '6563000005'.
    ENDIF.
  ENDLOOP.

  IF p_gl IS INITIAL.     "ITIS HD 9805
    IF hdr-vauart EQ 'ZFMC'.
      p_gl = '6563000005'.
    ELSE.
      p_gl = '6562000005'.
    ENDIF.
  ENDIF.
ENDFORM.                    " GET_GL_BASED_COSTELEMENT

*&---------------------------------------------------------------------*
*&      Form  GET_WO_DETAIL
*&---------------------------------------------------------------------*
FORM get_wo_detail USING p_aufnr TYPE aufnr
                   CHANGING ps_detail TYPE ty_wo_detail.

  ps_detail-aufnr = p_aufnr.

  SELECT SINGLE kostl erdat FROM aufk
    INTO (ps_detail-kostl, ps_detail-erdat)
    WHERE aufnr = p_aufnr.

  " Use current budget calculation row for cost center and amount
  IF list_wo-aufnr = p_aufnr.
    ps_detail-kostl = list_wo-kostl.
    ps_detail-wrbtr = list_wo-actual.
  ENDIF.

ENDFORM.                    " GET_WO_DETAIL

*&---------------------------------------------------------------------*
*&      Form  GET_EMAIL_FROM_DLI
*&---------------------------------------------------------------------*
FORM get_email_from_dli USING p_dli_name TYPE soobjinfi1-obj_name
                        CHANGING ct_recipients TYPE tt_email_recipient.

  DATA: dli_entries          LIKE sodlienti1 OCCURS 0 WITH HEADER LINE,
        ls_recipient         TYPE ty_email_recipient,
        lv_dli_name_internal TYPE soobjinfi1-obj_name.

  CLEAR ct_recipients.
  lv_dli_name_internal = p_dli_name.

  " Try shared DLI first
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

  " Fallback to personal DLI
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
    RETURN.
  ENDIF.

  LOOP AT dli_entries.
    IF dli_entries-member_adr IS NOT INITIAL.
      CLEAR ls_recipient.
      ls_recipient-recipient = dli_entries-member_adr.
      ls_recipient-name      = dli_entries-member_nam.
      APPEND ls_recipient TO ct_recipients.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " GET_EMAIL_FROM_DLI

*&---------------------------------------------------------------------*
*&      Form  GET_MINUS_RECIPIENTS
*&      Union of folder BPDH_HO (always) + BPDH_{WERKS} (conditional)
*&---------------------------------------------------------------------*
FORM get_minus_recipients USING p_werks TYPE werks_d
                           CHANGING p_recipients TYPE tt_email_recipient.

  DATA: lt_ho         TYPE tt_email_recipient,
        lt_cabang     TYPE tt_email_recipient,
        lv_folder_cbg TYPE soobjinfi1-obj_name.

  " 1. HO folder - ALWAYS read, for every Budget Minus WO
  PERFORM get_email_from_dli USING 'BPDH_HO' CHANGING lt_ho.

  IF lt_ho IS INITIAL.
    MESSAGE i398(00) WITH 'BPDH_HO is empty or not found -'
                           'check SBWP folder setup' ##MG_MISSING ##NO_TEXT.
  ENDIF.

  " 2. Build branch folder name dynamically from WO's WERKS, e.g. BPDH_JKT
  lv_folder_cbg = |BPDH_{ p_werks }|.
  CONDENSE lv_folder_cbg.

  " 3. Read branch folder - if not found, lt_cabang stays empty (not an error)
  PERFORM get_email_from_dli USING lv_folder_cbg CHANGING lt_cabang.

  IF lt_cabang IS INITIAL.
    MESSAGE i398(00) WITH 'WERKS' p_werks
                           'branch folder not found -' lv_folder_cbg ##MG_MISSING ##NO_TEXT.
  ENDIF.

  " 4. Union
  p_recipients = lt_ho.
  APPEND LINES OF lt_cabang TO p_recipients.

  " 5. Case-insensitive dedupe
  PERFORM dedupe_recipients CHANGING p_recipients.

ENDFORM.                    " GET_MINUS_RECIPIENTS

*&---------------------------------------------------------------------*
*&      Form  DEDUPE_RECIPIENTS
*&      Remove duplicate email addresses (case-insensitive)
*&---------------------------------------------------------------------*
FORM dedupe_recipients CHANGING p_recipients TYPE tt_email_recipient.

  LOOP AT p_recipients ASSIGNING FIELD-SYMBOL(<ls_rec>).
    <ls_rec>-recipient = to_upper( <ls_rec>-recipient ).
  ENDLOOP.

  SORT p_recipients BY recipient.
  DELETE ADJACENT DUPLICATES FROM p_recipients COMPARING recipient.

ENDFORM.                    " DEDUPE_RECIPIENTS

*&---------------------------------------------------------------------*
*&      Form  SEND_MINUS_EMAIL_PDH
*&---------------------------------------------------------------------*
FORM send_minus_email_pdh USING p_aufnr TYPE aufnr
                                 p_werks TYPE werks_d.

  DATA: lt_recipients    TYPE tt_email_recipient,
        lt_html          TYPE bcsy_text,
        ls_wo_detail     TYPE ty_wo_detail,
        lv_subject       TYPE so_obj_des,
        lv_aufnr_out     TYPE string,
        lv_wrbtr_out(25) TYPE c,
        lv_erdat_out(10) TYPE c,
        lv_count_c       TYPE string,
        lx_bcs           TYPE REF TO cx_bcs.

  PERFORM get_wo_detail USING p_aufnr CHANGING ls_wo_detail.

  PERFORM get_minus_recipients USING p_werks
                                CHANGING lt_recipients.

  IF lt_recipients IS INITIAL.
    MESSAGE i398(00) WITH 'WO' p_aufnr
                           'no valid recipient (BPDH_HO empty)' 'email not sent' ##MG_MISSING ##NO_TEXT.
    RETURN.
  ENDIF.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      input  = p_aufnr
    IMPORTING
      output = lv_aufnr_out.

  lv_subject = 'PEMBERITAHUAN BUDGET MINUS'.

  WRITE ls_wo_detail-wrbtr TO lv_wrbtr_out CURRENCY thdr-waers.
  IF ls_wo_detail-erdat IS NOT INITIAL.
    WRITE ls_wo_detail-erdat TO lv_erdat_out DD/MM/YYYY.
  ENDIF.

  APPEND '<html><body style="font-family:Arial,sans-serif;font-size:12px;">' TO lt_html.
  APPEND '<p>Dh ,</p>' TO lt_html.
  APPEND '<p>WO berikut belum tertransfer cost-nya karena BUDGET MINUS:</p>' TO lt_html.
  APPEND '<table border="1" cellpadding="6" style="border-collapse:collapse;">' TO lt_html.
  APPEND |<tr><td><b>No WO</b></td><td>{ lv_aufnr_out }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>Plant</b></td><td>{ p_werks }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>Cost Center</b></td><td>{ ls_wo_detail-kostl }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>Amount</b></td><td>{ lv_wrbtr_out }</td></tr>| TO lt_html.
  APPEND |<tr><td><b>WO Create Date</b></td><td>{ lv_erdat_out }</td></tr>| TO lt_html.
  APPEND '</table><br>' TO lt_html.
  APPEND '<p>Mohon segera dilakukan pengajuan penambahan budget melalui link berikut:<br>' &&
         '<a href="http://untr.id/f/FormSAbudgetJCSpart">Link Msflow SA Budget JCS</a></p>' TO lt_html.
  APPEND '<p>Terima kasih</p>' TO lt_html.
  APPEND '</body></html>' TO lt_html.

  TRY.
      PERFORM send_email_bcs TABLES lt_recipients
                             USING  lv_subject lt_html.
      lv_count_c = |{ lines( lt_recipients ) }|.
      MESSAGE i398(00) WITH 'WO' p_aufnr
                             'email sent to' lv_count_c ##MG_MISSING ##NO_TEXT.
    CATCH cx_bcs INTO lx_bcs.
      MESSAGE i398(00) WITH 'WO' p_aufnr
                             'send failed:' lx_bcs->get_text( ) ##MG_MISSING ##NO_TEXT.
  ENDTRY.

ENDFORM.                    " SEND_MINUS_EMAIL_PDH

*&---------------------------------------------------------------------*
*&      Form  SEND_EMAIL_BCS
*&---------------------------------------------------------------------*
FORM send_email_bcs TABLES pt_email LIKE gt_recipients
                    USING p_subject  TYPE so_obj_des
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
      lo_email = cl_bcs=>create_persistent( ).
      lv_subject = p_subject.

      lo_email_body = cl_document_bcs=>create_document(
                          i_type    = 'HTM'
                          i_text    = p_html_tab
                          i_subject = lv_subject ).

      lo_email->set_document( lo_email_body ).

      lo_internet_sender = cl_cam_address_bcs=>create_internet_address(
                              i_address_string = 'mail_sap@unitedtractors.com'
                              i_address_name   = 'PT. United Tractors Tbk' ).
      CALL METHOD lo_email->set_sender
        EXPORTING
          i_sender = lo_internet_sender.

      LOOP AT pt_email.
        l_address = pt_email-recipient.
        lo_receiver = cl_cam_address_bcs=>create_internet_address( l_address ).
        lo_email->add_recipient( i_recipient = lo_receiver
                                 i_express   = 'X' ).
      ENDLOOP.

      lo_email->set_send_immediately( 'X' ).

      lo_email->send( EXPORTING
                          i_with_error_screen = 'X'
                      RECEIVING
                          result = lv_send_result ).

      IF lv_send_result = 'X'.
        MESSAGE s000(db) WITH 'Email has been sent'.
      ENDIF.

      COMMIT WORK.

    CATCH cx_bcs INTO lx_exception.
      MESSAGE s000(db) WITH 'Email has not been sent'.
      RAISE EXCEPTION lx_exception.
  ENDTRY.

ENDFORM.                    " SEND_EMAIL_BCS