const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const os = require('os');

console.log('\n=============================================================');
console.log('⚡ TifoFlash - موجه إشعارات شاشات القفل (Apple APNs & Android)');
console.log('=============================================================\n');

// 1. Locate Service Account Key
function findServiceAccountKey() {
  const possiblePaths = [
    path.join(__dirname, 'service-account.json'),
    path.join(__dirname, '..', 'service-account.json'),
  ];

  for (const p of possiblePaths) {
    if (fs.existsSync(p)) return p;
  }

  // Check Downloads directory automatically for convenience!
  const downloadsDir = path.join(os.homedir(), 'Downloads');
  if (fs.existsSync(downloadsDir)) {
    try {
      const files = fs.readdirSync(downloadsDir);
      const keyFile = files.filter(f => f.toLowerCase().includes('tifoflash') && f.endsWith('.json'))
                           .sort((a, b) => fs.statSync(path.join(downloadsDir, b)).mtimeMs - fs.statSync(path.join(downloadsDir, a)).mtimeMs)[0];
      if (keyFile) {
        const src = path.join(downloadsDir, keyFile);
        const dest = path.join(__dirname, '..', 'service-account.json');
        fs.copyFileSync(src, dest);
        console.log(`📁 تم العثور على المفتاح في مجلد التنزيلات ونسخه تلقائياً: ${keyFile}`);
        return dest;
      }
    } catch (e) {}
  }

  return null;
}

const keyPath = findServiceAccountKey();

if (!keyPath) {
  console.log('⚠️ [تنبيه]: لم يتم العثور على ملف المفتاح بعد.');
  console.log('👉 اضغط الآن على الزر الأزرق في صفحة الفايربيس:');
  console.log('   [ Generate new private key ]');
  console.log('   (سيقوم هذا البرنامج باكتشافه من مجلد التنزيلات وتفعيله تلقائياً فور نزوله!)\n');
  console.log('⏳ جاري الانتظار...');

  // Poll for key file every 2 seconds
  const interval = setInterval(() => {
    const found = findServiceAccountKey();
    if (found) {
      clearInterval(interval);
      startDispatcher(found);
    }
  }, 2000);
} else {
  startDispatcher(keyPath);
}

function startDispatcher(certPath) {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(certPath, 'utf8'));

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: 'https://tifoflash-default-rtdb.europe-west1.firebasedatabase.app'
    });

    console.log('✅ تم تسجيل الدخول بنجاح إلى مشروع:', serviceAccount.project_id);
    console.log('📡 متصل الآن بطابور الإشعارات السريعة: /matches/match_2026_final/push_queue');
    console.log('🟢 الخدمة جاهزة ومستعدة — أي إشعار ترسله من لوحة التحكم سيصل لشاشات القفل فوراً!\n');

    const db = admin.database();
    const queueRef = db.ref('/matches/match_2026_final/push_queue');

    queueRef.on('child_added', async (snapshot) => {
      const payload = snapshot.val();
      const key = snapshot.key;

      if (!payload || payload._sent) return;

      const title = payload.title || 'تنبيه من إدارة الفعالية 📣';
      const body = payload.body || 'انضم للعرض الضوئي المباشر والتيفو الآن ⚡';
      const type = payload.type || 'LIVE_ALERT';

      console.log(`\n🔔 تم استلام طلب إشعار جديد من لوحة التحكم: "${title}"`);

      // Cross-platform payload (Apple APNs + Android Google Play Services)
      const message = {
        topic: 'all_fans',
        notification: {
          title: title,
          body: body,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'high_importance_channel',
            priority: 'max',
            defaultVibrateTimings: true,
            visibility: 'public',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: 'default',
              badge: 1,
              'content-available': 1,
            },
          },
        },
        data: {
          match_id: 'match_2026_final',
          type: type,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      try {
        const response = await admin.messaging().send(message);
        const time = new Date().toLocaleTimeString('ar-SA');
        console.log(`🚀 [${time}] تم إرسال الإشعار بنجاح لشاشات القفل لجميع هواتف (Apple + Android)!`);
        console.log(`   معرف الرسالة: ${response}`);

        // Mark as sent and remove from queue
        await queueRef.child(key).remove();
      } catch (err) {
        console.error('❌ حدث خطأ أثناء إرسال الإشعار عبر FCM:', err.message);
      }
    });

  } catch (e) {
    console.error('❌ خطأ في تشغيل الخدمة:', e);
  }
}
