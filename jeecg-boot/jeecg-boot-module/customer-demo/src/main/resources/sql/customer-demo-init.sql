CREATE TABLE IF NOT EXISTS c_demo_warehouse (
    id varchar(32) NOT NULL, code varchar(50), name varchar(100), address varchar(255),
    manager varchar(50), phone varchar(20), status int DEFAULT 1, create_by varchar(50),
    create_time datetime, update_by varchar(50), update_time datetime, del_flag int DEFAULT 0, PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS c_demo_warehouse_location (
    id varchar(32) NOT NULL, warehouse_id varchar(32), code varchar(100), location_type varchar(50),
    capacity decimal(10,2), status int DEFAULT 1, create_by varchar(50), create_time datetime,
    update_by varchar(50), update_time datetime, del_flag int DEFAULT 0, PRIMARY KEY (id), KEY idx_wh_id (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO sys_permission SELECT 'cust_demo_wh','','仓库管理','/customer/demo/warehouse','customer/demo/warehouse/index',1,1,10.00,'ant-design:database-filled',1,0,0,'1','admin',NOW()
WHERE NOT EXISTS(SELECT 1 FROM sys_permission WHERE id='cust_demo_wh');
INSERT INTO sys_permission SELECT 'cust_demo_wh_loc','','库位明细管理','/customer/demo/location','customer/demo/warehouse/location',1,1,11.00,'ant-design:environment-filled',1,0,0,'1','admin',NOW()
WHERE NOT EXISTS(SELECT 1 FROM sys_permission WHERE id='cust_demo_wh_loc');
INSERT INTO sys_role_permission SELECT REPLACE(UUID(),'-',''),'f6817f48af4fb3af11b9e8bf182f618b','cust_demo_wh',NOW(),'127.0.0.1'
WHERE NOT EXISTS(SELECT 1 FROM sys_role_permission WHERE role_id='f6817f48af4fb3af11b9e8bf182f618b' AND permission_id='cust_demo_wh');
INSERT INTO sys_role_permission SELECT REPLACE(UUID(),'-',''),'f6817f48af4fb3af11b9e8bf182f618b','cust_demo_wh_loc',NOW(),'127.0.0.1'
WHERE NOT EXISTS(SELECT 1 FROM sys_role_permission WHERE role_id='f6817f48af4fb3af11b9e8bf182f618b' AND permission_id='cust_demo_wh_loc');
