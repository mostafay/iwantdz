# خطة إعادة تنظيم المحطة

## النظام الجديد للمشاريع

### المشروع الرئيسي
- **المسار:** `C:\Users\gqwxg\OneDrive\Desktop\0\iwantdz`
- **الوصف:** مشروع Flutter (Frontend) + Backend
- **Backend:** `C:\Users\gqwxg\OneDrive\Desktop\0\iwantdz\backend`

### المشاريع المحذوفة
- ~~`C:\Users\gqwxg\OneDrive\Desktop\iwantdz`~~ (تم الاستغناء عنه)
- ~~`C:\Users\gqwxg\OneDrive\Desktop\iwantdz-main`~~ (تم الاستغناء عنه)

## المستودعات على الشبكة (GitHub)

### المستودع الرئيسي
- **Remote Name:** `origin`
- **URL:** `https://github.com/mostafay/iwantdz.git`
- **الاستخدام:** الرفع الرئيسي للمشروع

### النسخة الاحتياطية
- **Remote Name:** `backup`
- **URL:** `https://github.com/mostafay/iwantdzBucap.git`
- **الاستخدام:** النسخة الاحتياطية عند الحاجة

## أوامر Git

### الرفع للمستودع الرئيسي
```bash
git add .
git commit -m "رسالة الالتزام"
git push origin main
```

### الرفع للنسخة الاحتياطية
```bash
git add .
git commit -m "رسالة الالتزام"
git push backup main
```

### عرض المستودعات
```bash
git remote -v
```

## الملفات الرئيسية في Backend

- **server.js** - السيرفر الرئيسي (93,064 bytes)
- **GExel.js** - استيراد البيانات من Google Sheets و JSON (31,226 bytes)
- **iwantdz_db.text** - النسخة الاحتياطية لقاعدة البيانات
- **docker-compose.yml** - إعدادات Docker لـ MySQL
- **.env** - متغيرات البيئة

## التاريخ

- **تاريخ الإعداد:** 21 أغسطس 2026
- **آخر تحديث:** إصلاح تسجيل المستخدم وإضافة عمود password
