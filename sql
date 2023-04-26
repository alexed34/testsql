 /*
  Александров Э.
  Задача 306304
	"ЖУРНАЛ (ФОРМА N 157/у-93)"	регистрации исследований, выполняемых в отделении функциональной диагностики
*/
 -- select 1 ROW_NUMBER, 1 RTREATDATE, 1 SCHNAME, 1 FULLNAME, 1 AGEINYEARS, 1 FULLNAME1, 1 DEPNAME, 1 DNAME, 1 KLADR_ADDRFULL, 1 MKBCODE, 1 ZAKL, 1 OBORUD from dual

execute block
returns
(
 ROW_NUMBER int,
 RTREATDATE        
 clreferrals.RTREATDATE ,
 SCHNAME           type of column  wschema.SCHNAME,
 FULLNAME          type of column  clients.FULLNAME,
 AGEINYEARS        type of column  paramsinfo.valuetext,
 FULLNAME1         type of column  filials.FULLNAME,
 DEPNAME           type of column  departments.DEPNAME,
 DNAME             type of column  doctor.DNAME,
 KLADR_ADDRFULL    type of column  clients.KLADR_ADDRFULL,
 mkbcode            type of column  diagnosis.mkbcode,
 ZAKL              type of column  paramsinfo.valuetext,
 OBORUD            type of column  paramsinfo.valuetext
)
as
declare sql_response TTEXT4096;
declare filid type of column filials.filid;
declare dbpath type of column filials.dbpath;
declare current_filial type of column filials.filid;
declare i int;
begin
sql_response = '
SELECT  row_number() OVER (ORDER BY rtreatdate)  ROW_NUMBER
	, RTREATDATE
	, KOD AS SCHNAME
	, FULLNAME
	, AGEINYEARS
	, MO || '' '' || iif(CHAIR IS NULL, '' '', CHAIR) FULLNAME1
	, DEPNAME
	, DNAME
	, KLADR_ADDRFULL
	, MKBCODE
	, ZAKL
	, OBORUD
FROM (
	SELECT cl.rtreatdate
		, w.kodoper || '' '' || w.schname AS kod
		, c.fullname
		, iif(AGEINYEARS > 3, AGEINYEARS, AGEINYEARS || '' год '' || EXTRAMONTHS || '' мес.'') AGEINYEARS
		-- , cl.rtreatdate
		, f.fullname mo
		, (
			SELECT chname
			FROM h_schedule h
			LEFT JOIN chairs c ON h.placeid = c.chid
			WHERE 1 = 1
				AND h.pcode = tr.pcode
				AND cast(workdate AS DATE) <= cl.rtreatdate
				AND (
					cast(enddate AS DATE) >= cl.rtreatdate
					OR enddate IS NULL
					)
			) chair
		, d.depname
		, dc.dname
		, c.kladr_addrfull
		, dg.mkbcode
		, p.valuetext zakl
		, p2.valuetext oborud
	FROM clreferrals cl
	LEFT JOIN clrefdet cd ON cd.refid = cl.refid
	LEFT JOIN wschema w ON w.schid = cd.schid
	LEFT JOIN clients c ON c.pcode = cl.pcode
	LEFT JOIN filials f ON f.filid = cl.fromfilial
	LEFT JOIN departments d ON d.depnum = cl.fromdepart
	LEFT JOIN doctor dc ON dc.dcode = cl.dcode
	LEFT JOIN diagnosis dg ON dg.dgcode = cl.dgcode
	INNER JOIN treat tr ON tr.treatcode = cl.rtreatcode
	LEFT JOIN getage(c.bdate, CURRENT_DATE) ON 1 = 1
	LEFT JOIN (
		SELECT valuetext
			, treatcode
		FROM paramsinfo
		WHERE codeparams IN (990104425, 990104461, 990104411, 990098220, 990090057, 990089299, 990083839, 990048524, 990023810, 990019555)
		) p ON p.treatcode = cl.rtreatcode
	LEFT JOIN (
		SELECT valuetext
			, treatcode
		FROM paramsinfo
		WHERE codeparams IN (990019458, 990104390, 990083664, 990104412, 990104426, 990105580, 990105578, 990105583, 990105583, 990104619)
		) p2 ON p2.treatcode = cl.rtreatcode
	WHERE 1 = 1
		AND todepart = 1014 -- отделение Функциональная диагностика
		AND cl.treatdate BETWEEN ''24.04'' AND ''26.04''
		AND cl.reftype IN (13000371, 13000372) --- тип направления: "Функц. Внешние ЛПУ" или "Функц. Внутр.";
		AND cd.schid IN (990093441, 990093610, 990093618, 990093621, 990093623, 990093628, 990093741, 990093745, 990093769, 990095501) -- метод исследования
		AND tr.placeid IN (990002161, 990002659, 990002665, 990003698, 990005013, 990005177, 990005204, 990005397, 990005515, 990005516, 990005517) -- заключение протоколы
	) qq
';
select keyvalue from m_config where lower(keyname)='filial' into current_filial;
for select f.filid, f.dbpath from filials f
where (f.filid in ([filial])) and f.filid <> :current_filial
union
select f.filid, f.dbpath from filials f
where f.filid = :current_filial and (:current_filial in ([filial]) or -1 in ([filial]))
into filid, dbpath
 do
 begin
 if (:filid = :current_filial) then
  begin

   for execute statement (sql_response)
   into  ROW_NUMBER,RTREATDATE,SCHNAME,FULLNAME,AGEINYEARS,FULLNAME1,DEPNAME,DNAME,KLADR_ADDRFULL,mkbcode,ZAKL ,OBORUD
   do
   suspend;
   end
 else begin
  for execute statement (sql_response)
  on external :dbpath as User Current_User role current_role PassWord 'PDNTP'
  into ROW_NUMBER,RTREATDATE,SCHNAME,FULLNAME,AGEINYEARS,FULLNAME1,DEPNAME,DNAME,KLADR_ADDRFULL,mkbcode,ZAKL ,OBORUD
  do suspend;
             when any do
                begin
                ROW_NUMBER = null ;
                RTREATDATE= null   ;
                SCHNAME = null     ;
                FULLNAME = null    ;
                AGEINYEARS= null    ;
                FULLNAME1=  'База не доступна '||:filid||' '|| :FULLNAME1   ;
                DEPNAME= null   ;
                DNAME= null      ;
                KLADR_ADDRFULL= null  ;
                MKBCODE= null     ;
                ZAKL= null       ;
                OBORUD = null    ;

                 suspend;
                end


    end
  end
end








