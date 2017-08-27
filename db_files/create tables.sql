CREATE TABLE income
(
  geoid character varying COLLATE pg_catalog."default",
  geoid2 character varying COLLATE pg_catalog."default",
  geodisplaylabel character varying COLLATE pg_catalog."default",
  hc02_est_vc02 double precision
);

CREATE TABLE race
(
  geoid character varying COLLATE pg_catalog."default",
  geoid2 character varying COLLATE pg_catalog."default",
  geodisplaylabel character varying COLLATE pg_catalog."default",
  hd01_vd01 double precision,
  hd02_vd01 character varying COLLATE pg_catalog."default",
  hd01_vd02 double precision,
  hd02_vd02 character varying COLLATE pg_catalog."default",
  hd01_vd03 double precision,
  hd02_vd03 double precision,
  hd01_vd04 double precision,
  hd02_vd04 double precision,
  hd01_vd05 double precision,
  hd02_vd05 double precision,
  hd01_vd06 double precision,
  hd02_vd06 double precision,
  hd01_vd07 double precision,
  hd02_vd07 double precision,
  hd01_vd08 double precision,
  hd02_vd08 double precision,
  hd01_vd09 double precision,
  hd02_vd09 double precision,
  hd01_vd10 double precision,
  hd02_vd10 double precision,
  hd01_vd11 double precision,
  hd02_vd11 double precision,
  hd01_vd12 double precision,
  hd02_vd12 character varying COLLATE pg_catalog."default",
  hd01_vd13 double precision,
  hd02_vd13 double precision,
  hd01_vd14 double precision,
  hd02_vd14 double precision,
  hd01_vd15 double precision,
  hd02_vd15 double precision,
  hd01_vd16 double precision,
  hd02_vd16 double precision,
  hd01_vd17 double precision,
  hd02_vd17 double precision,
  hd01_vd18 double precision,
  hd02_vd18 double precision,
  hd01_vd19 double precision,
  hd02_vd19 double precision,
  hd01_vd20 double precision,
  hd02_vd20 double precision,
  hd01_vd21 double precision,
  hd02_vd21 double precision
);


CREATE TABLE president_race
(
  vtd character varying COLLATE pg_catalog."default",
  cntyvtd character varying COLLATE pg_catalog."default",
  d double precision,
  r double precision,
  winner character varying COLLATE pg_catalog."default"
);


CREATE TABLE election_results
(
  county character(30) COLLATE pg_catalog."default",
  fips smallint,
  vtd character varying COLLATE pg_catalog."default",
  cntyvtd character varying COLLATE pg_catalog."default",
  office character varying COLLATE pg_catalog."default",
  name_can character varying COLLATE pg_catalog."default",
  party character(1) COLLATE pg_catalog."default",
  incumbent character(1) COLLATE pg_catalog."default",
  votes integer
);


CREATE TABLE racial_dot_density AS 
SELECT n.geoid2,ST_GeneratePoints(b.geom,n.hispanic) AS hispanic_points,
ST_GeneratePoints(b.geom,n.white) AS white_points,
ST_GeneratePoints(b.geom,n.black) AS black_points,
ST_GeneratePoints(b.geom,n.native) AS native_points,
ST_GeneratePoints(b.geom,n.asian) AS asian_points

FROM tx_tracts b JOIN 
                         
                         (SELECT geoid2,
                         (hd01_vd12/100)::int AS hispanic,
                         (hd01_vd03/100)::int AS white,
                         (hd01_vd04/100)::int AS black,
                         (hd01_vd05/100)::int AS native,
                         (hd01_vd06/100)::int AS asian
                         
                         FROM race)n ON n.geoid2=CONCAT(b.statefp,b.countyfp,b.tractce)
;


CREATE TABLE votes_dot_density AS 
SELECT b.cntyvtd,ST_GeneratePoints(b.geom,(president_race.d/10)::int) AS d_points,
ST_GeneratePoints(b.geom,(president_race.r/10)::int) AS r_points

FROM voting_districts_1 b JOIN 
 president_race ON 
 president_race.cntyvtd=b.cntyvtd;

