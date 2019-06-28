import pymysql

def connection():
	    try:
        conn = pymysql.connect(host="hostname",user="root",passwd="password",port=3306, db="Game" )
        print("connected.")
        return conn
    except Exception as e:
        print(e)

# prepare a cursor object using cursor() method
db = connection()
cursor = db.cursor()
cursor.execute("DROP TABLE IF EXISTS ASSIGNMENT")
# Create table as per requirement
sql = """CREATE TABLE ASSIGNMENT (
   FIRST_NAME  CHAR(20) NOT NULL,
   LAST_NAME  CHAR(20),
   AGE INT,  
   SEX CHAR(1),
   INCOME FLOAT )"""

cursor.execute(sql)
print("created table")


#Performing CRUD operations

#Inserting items in the table (Create)
cursor.execute("INSERT INTO ASSIGNMENT(FIRST_NAME, LAST_NAME, AGE, SEX, INCOME) VALUES ('Sam', 'Jake', 65, 'M', 20000)")
cursor.execute("INSERT INTO ASSIGNMENT(FIRST_NAME, LAST_NAME, AGE, SEX, INCOME) VALUES ('Blake', 'Brown', 20, 'M', 20500)")
cursor.execute("INSERT INTO ASSIGNMENT(FIRST_NAME, LAST_NAME, AGE, SEX, INCOME) VALUES ('Sela', 'Harding', 25, 'F', 26000)")
