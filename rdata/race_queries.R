race_by_district =dbGetQuery(connection,"
                      SELECT
                         m.gid,
                         ROUND(SUM(m.proportion*m.hispanic)) AS hispanic, 
                         ROUND(SUM(m.proportion*m.white)) AS white, 
                         ROUND(SUM(m.proportion*m.black)) AS black, 
                         ROUND(SUM(m.proportion*m.native)) AS native, 
                         ROUND(SUM(m.proportion*m.asian)) AS asian 
                         FROM
                         (
                         SELECT b.gid AS tract_gid, t.gid AS gid, 
                         (st_area( st_intersection( 
                         b.geom, 
                         t.geom ) ) / 
                         st_area(b.geom ) ) 
                         AS proportion,
                         n.hispanic,
                         n.white,
                         n.black,
                         n.native,
                         n.asian
                         from tx_congress t, 
                         tx_tracts b
                         JOIN 
                         
                         (SELECT geoid2,
                         hd01_vd12 AS hispanic,
                         hd01_vd03 AS white,
                         hd01_vd04 AS black,
                         hd01_vd05 AS native,
                         hd01_vd06 AS asian
                         
                         FROM race)n ON n.geoid2=CONCAT(b.statefp,b.countyfp,b.tractce)
                         
                         where st_intersects( 
                         b.geom, 
                         t.geom) 
                         and (st_area( 
                         st_intersection( 
                         b.geom, 
                         t.geom)) / 
                         st_area( b.geom )) >.4)m
                         
                         GROUP BY m.gid
                         
                         ")

income_by_district=dbGetQuery(connection,"SELECT
m.gid,round(AVG(m.median_income))
FROM
(
SELECT b.gid AS tract_gid, t.gid, 
n.median_income
 from tx_congress t, 
 tx_tracts b
 JOIN 
 
 (SELECT income.geoid2,
income.hc02_est_vc02 AS median_income

FROM income WHERE hc02_est_vc02 IS NOT NULL)n ON n.geoid2=CONCAT(b.statefp,b.countyfp,b.tractce)
 
 where st_intersects( 
     b.geom, 
     t.geom) 
)m
GROUP BY m.gid
")
