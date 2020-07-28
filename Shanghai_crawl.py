from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
#from selenium import webelement

# options to look like a human
options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-gpu")

options.add_argument("window-size=1920x1080")
options.add_argument("lang=ko_KR")
options.add_argument("user-agent=Chrome/77.0.3865.90")

# to save error log
service_args = ['--verbose']
service_log_path = "/chromedriver.log"
# service_log_path = "/home/dbXXXXXX/chromedriver.log"
### when connect to stat-ibm

driver = webdriver.Chrome(executable_path = '/usr/bin/chromedriver',
                          options = options)
driver.implicitly_wait(5)
driver.get('https://ko.skyticket.com/international-flights/ia_fare_result_mix.php?select_career_only_flg=&trip_type=2&dep_port_name0=%EC%84%9C%EC%9A%B8%28SEL%29&dep_port0=SEL&arr_port_name0=%EC%83%81%ED%95%98%EC%9D%B4%28SHA%29&arr_port0=SHA&dep_date%5B%5D=2020-01-13&dep_port_name1=%ED%8C%8C%EB%A6%AC%28CDG%29&dep_port1=CDG&arr_port_name1=%EC%84%9C%EC%9A%B8%28SEL%29&arr_port1=SEL&dep_date%5B%5D=2020-01-20&cabin_class=Y&adt_pax=1&chd_pax=0&inf_pax=0&ssid=98808c0db017a2370690457fc1d0812e')

driver.implicitly_wait(10)
source = driver.find_element_by_id('div_result')

import pymysql

conn = pymysql.connect(host = "203.252.196.68",
                       user = 'db1611164', passwd = 'stat1234', db = 'sql1611164')

cur = conn.cursor()

price = source.find_elements_by_class_name('currency_conversion')
flight_no = source.find_elements_by_class_name('flight_no')
dep_time = source.find_elements_by_class_name('st_time')
arr_time = source.find_elements_by_class_name('end_time')
n = int(len(flight_no)/2)

for i in range(0,20):
  flight_price = price[3 + 4*i].get_attribute("innerHTML")
  temp_flight = flight_no[2*i].get_attribute("innerHTML")
  temp_flight = temp_flight.split('>')[1]
  flight1 = temp_flight.split('<')[0]
  temp_time = dep_time[2*i].get_attribute("innerHTML")
  temp_time = temp_time.split('>')[1]
  dep_date1 = temp_time.split('<')[0]
  temp_time = dep_time[2*i].get_attribute("innerHTML")
  temp_time = temp_time.split('>')[2]
  dep_time1 = temp_time.split('<')[0]
  temp_time = arr_time[2*i].get_attribute("innerHTML")
  temp_time = temp_time.split('>')[1]
  arr_date1 = temp_time.split('<')[0]
  temp_time = arr_time[2*i].get_attribute("innerHTML")
  temp_time = temp_time.split('>')[4]
  arr_time1 = temp_time.split('<')[0]
  temp_flight = flight_no[2*i+1].get_attribute("innerHTML")
  temp_flight = temp_flight.split('>')[1]
  flight2 = temp_flight.split('<')[0]
  temp_time = dep_time[2*i+1].get_attribute("innerHTML")
  temp_time = temp_time.split('>')[1]
  dep_date2 = temp_time.split('<')[0]
  temp_time = dep_time[2*i+1].get_attribute("innerHTML")
  temp_time = temp_time.split('>')[2]
  dep_time2 = temp_time.split('<')[0]
  temp_time = arr_time[2*i+1].get_attribute("innerHTML")
  temp_time = temp_time.split('>')[1]
  arr_date2 = temp_time.split('<')[0]
  temp_time = arr_time[2*i+1].get_attribute("innerHTML")
  temp_time = temp_time.split('>')[4]
  arr_time2 = temp_time.split('<')[0]
  print(flight_price, flight1, dep_date1, dep_time1, arr_date1, arr_time1, flight2, dep_date2, dep_time2, arr_date2, arr_time2)
  myquery5 = """
  SELECT COUNT(*) FROM Shanghai_MetaData_v1 as T
  WHERE T.FLIGHT_CODE1 = %s AND T.DEP_TIME1 = %s AND T.FLIGHT_CODE2 = %s AND T.DEP_TIME2 = %s
  """
  cur.execute(myquery5, (flight1, dep_time1, flight2, dep_time2))
  exist = cur.fetchall()
  if exist[0][0] == 0:
    myquery2 = """
    INSERT IGNORE INTO Shanghai_MetaData_v1(FLIGHT_CODE1, DEP_DATE1, DEP_TIME1, ARR_DATE1, ARR_TIME1, FLIGHT_CODE2, DEP_DATE2, DEP_TIME2, ARR_DATE2, ARR_TIME2)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
    """
    cur.execute(myquery2, (flight1, dep_date1, dep_time1, arr_date1, arr_time1, flight2, dep_date2, dep_time2, arr_date2, arr_time2))
    conn.commit()
  myquery3="""
  SELECT * FROM Shanghai_MetaData_v1;
  """
  num = cur.execute(myquery3)
  MetaData = cur.fetchall()
  for j in range(0, num):
    if flight1 == MetaData[j][1] and dep_time1 == MetaData[j][3] and flight2 == MetaData[j][6] and dep_time2 == MetaData[j][8]:
      myquery4="""
      INSERT INTO Shanghai_Price_v1(FLIGHT_ID, PRICE)
      VALUES (%s, %s) ;
      """
      cur.execute(myquery4, (MetaData[j][0], flight_price))
      conn.commit()


cur.close()
conn.close()