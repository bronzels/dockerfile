use tpcds_bin_partitioned_orc_10
;
SELECT
  i_item_id,
  i_item_desc,
  i_current_price
FROM item, inventory, date_dim, store_sales
WHERE i_current_price BETWEEN 62 AND 62 + 30
  AND inv_item_sk = i_item_sk
  AND d_date_sk = inv_date_sk
  AND d_date BETWEEN cast('2000-05-25' AS DATE) AND DATE_ADD(CAST('2000-05-25' AS DATE), INTERVAL 60 DAY)
  AND i_manufact_id IN (129, 270, 821, 423)
  AND inv_quantity_on_hand BETWEEN 100 AND 500
  AND ss_item_sk = i_item_sk
GROUP BY i_item_id, i_item_desc, i_current_price
ORDER BY i_item_id
LIMIT 100
;
