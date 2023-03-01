-- 参考hadoop/hive/image/ddl-tpcds-bin_partitioned

DROP DATABASE IF EXISTS hive_tpcds_orc_10_manual_imported_few;
CREATE DATABASE hive_tpcds_orc_10_manual_imported_few;
USE hive_tpcds_orc_10_manual_imported_few;


-- dim
-- 1+2
create table if not exists date_dim(
                                       `d_date_sk` bigint,
                                       `d_date_id` char(16),
    `d_date` date,
    `d_month_seq` int,
    `d_week_seq` int,
    `d_quarter_seq` int,
    `d_year` int,
    `d_dow` int,
    `d_moy` int,
    `d_dom` int,
    `d_qoy` int,
    `d_fy_year` int,
    `d_fy_quarter_seq` int,
    `d_fy_week_seq` int,
    `d_day_name` char(9),
    `d_quarter_name` char(6),
    `d_holiday` char(1),
    `d_weekend` char(1),
    `d_following_holiday` char(1),
    `d_first_dom` int,
    `d_last_dom` int,
    `d_same_day_ly` int,
    `d_same_day_lq` int,
    `d_current_day` char(1),
    `d_current_week` char(1),
    `d_current_month` char(1),
    `d_current_quarter` char(1),
    `d_current_year` char(1))
DUPLICATE KEY(`d_date_sk`, `d_date_id`)
DISTRIBUTED BY HASH(`d_date_sk`) BUCKETS 4
;


-- 1
create table if not exists store_returns
(`sr_returned_date_sk` bigint,
 `sr_return_time_sk` bigint,
    `sr_item_sk` bigint,
    `sr_customer_sk` bigint,
    `sr_cdemo_sk` bigint,
    `sr_hdemo_sk` bigint,
    `sr_addr_sk` bigint,
    `sr_store_sk` bigint,
    `sr_reason_sk` bigint,
    `sr_ticket_number` bigint,
    `sr_return_quantity` int,
    `sr_return_amt` decimal(7,2),
    `sr_return_tax` decimal(7,2),
    `sr_return_amt_inc_tax` decimal(7,2),
    `sr_fee` decimal(7,2),
    `sr_return_ship_cost` decimal(7,2),
    `sr_refunded_cash` decimal(7,2),
    `sr_reversed_charge` decimal(7,2),
    `sr_store_credit` decimal(7,2),
    `sr_net_loss` decimal(7,2)
    )
DUPLICATE KEY(`sr_returned_date_sk`, `sr_return_time_sk`, `sr_item_sk`, `sr_customer_sk`)
-- PARTITION BY RANGE(sr_returned_date_sk) ()
DISTRIBUTED BY HASH(sr_returned_date_sk)
-- PROPERTIES
-- (
--     "dynamic_partition.enable" = "true",
--     "dynamic_partition.time_unit" = "DAY",
--     "dynamic_partition.end" = "1",
--     "dynamic_partition.prefix" = "pd",
--     "dynamic_partition.buckets" = "64"
-- )
;

create table if not exists store(
                                    `s_store_sk` bigint,
                                    `s_store_id` char(16),
    `s_rec_start_date` date,
    `s_rec_end_date` date,
    `s_closed_date_sk` bigint,
    `s_store_name` varchar(50),
    `s_number_employees` int,
    `s_floor_space` int,
    `s_hours` char(20),
    `s_manager` varchar(40),
    `s_market_id` int,
    `s_geography_class` varchar(100),
    `s_market_desc` varchar(100),
    `s_market_manager` varchar(40),
    `s_division_id` int,
    `s_division_name` varchar(50),
    `s_company_id` int,
    `s_company_name` varchar(50),
    `s_street_number` varchar(10),
    `s_street_name` varchar(60),
    `s_street_type` char(15),
    `s_suite_number` char(10),
    `s_city` varchar(60),
    `s_county` varchar(30),
    `s_state` char(2),
    `s_zip` char(10),
    `s_country` varchar(20),
    `s_gmt_offset` decimal(5,2),
    `s_tax_percentage` decimal(5,2)
    )
DUPLICATE KEY(`s_store_sk`, `s_store_id`)
DISTRIBUTED BY HASH(`s_store_sk`) BUCKETS 8
;


create table if not exists customer(
                                       `c_customer_sk` bigint,
                                       `c_customer_id` char(16),
    `c_current_cdemo_sk` bigint,
    `c_current_hdemo_sk` bigint,
    `c_current_addr_sk` bigint,
    `c_first_shipto_date_sk` bigint,
    `c_first_sales_date_sk` bigint,
    `c_salutation` char(10),
    `c_first_name` char(20),
    `c_last_name` char(30),
    `c_preferred_cust_flag` char(1),
    `c_birth_day` int,
    `c_birth_month` int,
    `c_birth_year` int,
    `c_birth_country` varchar(20),
    `c_login` char(13),
    `c_email_address` char(50),
    `c_last_review_date_sk` bigint)
DUPLICATE KEY(`c_customer_sk`, `c_customer_id`)
DISTRIBUTED BY HASH(`c_customer_sk`) BUCKETS 8
;



-- 2
create table if not exists web_sales( `ws_sold_date_sk` bigint,
                                        `ws_sold_time_sk` bigint,
                                        `ws_ship_date_sk` bigint,
                                        `ws_item_sk` bigint,
                                        `ws_bill_customer_sk` bigint,
                                        `ws_bill_cdemo_sk` bigint,
                                        `ws_bill_hdemo_sk` bigint,
                                        `ws_bill_addr_sk` bigint,
                                        `ws_ship_customer_sk` bigint,
                                        `ws_ship_cdemo_sk` bigint,
                                        `ws_ship_hdemo_sk` bigint,
                                        `ws_ship_addr_sk` bigint,
                                        `ws_web_page_sk` bigint,
                                        `ws_web_site_sk` bigint,
                                        `ws_ship_mode_sk` bigint,
                                        `ws_warehouse_sk` bigint,
                                        `ws_promo_sk` bigint,
                                        `ws_order_number` bigint,
                                        `ws_quantity` int,
                                        `ws_wholesale_cost` decimal(7,2),
    `ws_list_price` decimal(7,2),
    `ws_sales_price` decimal(7,2),
    `ws_ext_discount_amt` decimal(7,2),
    `ws_ext_sales_price` decimal(7,2),
    `ws_ext_wholesale_cost` decimal(7,2),
    `ws_ext_list_price` decimal(7,2),
    `ws_ext_tax` decimal(7,2),
    `ws_coupon_amt` decimal(7,2),
    `ws_ext_ship_cost` decimal(7,2),
    `ws_net_paid` decimal(7,2),
    `ws_net_paid_inc_tax` decimal(7,2),
    `ws_net_paid_inc_ship` decimal(7,2),
    `ws_net_paid_inc_ship_tax` decimal(7,2),
    `ws_net_profit` decimal(7,2)
    )
DUPLICATE KEY(`ws_sold_date_sk`, `ws_sold_time_sk`, `ws_ship_date_sk`, `ws_item_sk`, `ws_bill_customer_sk`)
-- PARTITION BY RANGE(ws_ship_date_sk) ()
DISTRIBUTED BY HASH(ws_ship_date_sk)
-- PROPERTIES
--
--    "dynamic_partition.enable" = "true",
--    "dynamic_partition.time_unit" = "DAY",
--    "dynamic_partition.end" = "1",
--    "dynamic_partition.prefix" = "pd",
--    "dynamic_partition.buckets" = "64"
--
;


create table if not exists catalog_sales(    `cs_sold_date_sk` bigint,
                                             `cs_sold_time_sk` bigint,
                                            `cs_ship_date_sk` bigint,
                                            `cs_bill_customer_sk` bigint,
                                            `cs_bill_cdemo_sk` bigint,
                                            `cs_bill_hdemo_sk` bigint,
                                            `cs_bill_addr_sk` bigint,
                                            `cs_ship_customer_sk` bigint,
                                            `cs_ship_cdemo_sk` bigint,
                                            `cs_ship_hdemo_sk` bigint,
                                            `cs_ship_addr_sk` bigint,
                                            `cs_call_center_sk` bigint,
                                            `cs_catalog_page_sk` bigint,
                                            `cs_ship_mode_sk` bigint,
                                            `cs_warehouse_sk` bigint,
                                            `cs_item_sk` bigint,
                                            `cs_promo_sk` bigint,
                                            `cs_order_number` bigint,
                                            `cs_quantity` int,
                                            `cs_wholesale_cost` decimal(7,2),
    `cs_list_price` decimal(7,2),
    `cs_sales_price` decimal(7,2),
    `cs_ext_discount_amt` decimal(7,2),
    `cs_ext_sales_price` decimal(7,2),
    `cs_ext_wholesale_cost` decimal(7,2),
    `cs_ext_list_price` decimal(7,2),
    `cs_ext_tax` decimal(7,2),
    `cs_coupon_amt` decimal(7,2),
    `cs_ext_ship_cost` decimal(7,2),
    `cs_net_paid` decimal(7,2),
    `cs_net_paid_inc_tax` decimal(7,2),
    `cs_net_paid_inc_ship` decimal(7,2),
    `cs_net_paid_inc_ship_tax` decimal(7,2),
    `cs_net_profit` decimal(7,2)
)
DUPLICATE KEY(`cs_sold_date_sk`, `cs_sold_time_sk`, `cs_ship_date_sk`, `cs_bill_customer_sk`)
-- PARTITION BY RANGE(cs_sold_date_sk) ()
DISTRIBUTED BY HASH(cs_sold_date_sk)
-- PROPERTIES
-- (
--     "dynamic_partition.enable" = "true",
--     "dynamic_partition.time_unit" = "DAY",
--     "dynamic_partition.end" = "1",
--     "dynamic_partition.prefix" = "pd",
--     "dynamic_partition.buckets" = "64"
-- )
;



-- 9
create table if not exists store_sales(`ss_sold_date_sk` bigint,
                                          `ss_sold_time_sk` bigint,
                                          `ss_item_sk` bigint,
                                          `ss_customer_sk` bigint,
                                          `ss_cdemo_sk` bigint,
                                          `ss_hdemo_sk` bigint,
                                          `ss_addr_sk` bigint,
                                          `ss_store_sk` bigint,
                                          `ss_promo_sk` bigint,
                                          `ss_ticket_number` bigint,
                                          `ss_quantity` int,
                                          `ss_wholesale_cost` decimal(7,2),
    `ss_list_price` decimal(7,2),
    `ss_sales_price` decimal(7,2),
    `ss_ext_discount_amt` decimal(7,2),
    `ss_ext_sales_price` decimal(7,2),
    `ss_ext_wholesale_cost` decimal(7,2),
    `ss_ext_list_price` decimal(7,2),
    `ss_ext_tax` decimal(7,2),
    `ss_coupon_amt` decimal(7,2),
    `ss_net_paid` decimal(7,2),
    `ss_net_paid_inc_tax` decimal(7,2),
    `ss_net_profit` decimal(7,2)
    )
DUPLICATE KEY(`ss_sold_date_sk`, `ss_sold_time_sk`, `ss_item_sk`, `ss_customer_sk`)
-- PARTITION BY RANGE(ss_sold_date_sk) ()
DISTRIBUTED BY HASH(ss_sold_date_sk)
-- PROPERTIES
-- (
--     "dynamic_partition.enable" = "true",
--     "dynamic_partition.time_unit" = "DAY",
--     "dynamic_partition.end" = "1",
--     "dynamic_partition.prefix" = "pd",
--     "dynamic_partition.buckets" = "64"
-- )
;


create table if not exists reason(
                                     `r_reason_sk` bigint,
                                     `r_reason_id` char(16),
    `r_reason_desc` char(100)
    )
DUPLICATE KEY(`r_reason_sk`, `r_reason_id`)
DISTRIBUTED BY HASH(`r_reason_sk`) BUCKETS 4
;

