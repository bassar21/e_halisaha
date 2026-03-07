const express = require('express');
const db = require('../config/database');
const { authMiddleware, roleMiddleware } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');

// Multer Storage Configuration for Pitch Images
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/pitches/');
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + Math.round(Math.random() * 1E9) + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

const router = express.Router();

// --- BÜTÜN SAHALARI (PITCHES) GETİR ---
router.get('/', async (req, res) => {
    try {
        const result = await db.query(`
            SELECT 
                p.id, p.name, p.hourly_price as price, p.deposit_price as deposit, 
                p.type, p.capacity, p.opening_hour, p.closing_hour, p.slot_duration,
                p.water_price, p.cleats_price, p.gloves_price,
                f.address, f.district, f.city, f.image_url, f.owner_id,
                u.email as owner_email
            FROM pitches p
            LEFT JOIN facilities f ON p.facility_id = f.id
            LEFT JOIN users u ON f.owner_id = u.id
            WHERE p.is_active = true
            ORDER BY p.created_at DESC
        `);
        res.json({ success: true, count: result.rows.length, data: result.rows });
    } catch (error) {
        console.error('Saha Getirme Hatası:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// --- YENİ SAHA EKLE ---
router.post('/', authMiddleware, roleMiddleware('isletme', 'admin', 'sahasahibi'), async (req, res) => {
    try {
        const {
            name, hourlyPrice, type, capacity, depositPrice,
            openingHour, closingHour, slotDuration, district, address, ownerId
        } = req.body;

        let parsedOwnerId = parseInt(ownerId, 10);
        if (isNaN(parsedOwnerId)) parsedOwnerId = req.user.id;

        // Tesis (Facility) var mı kontrol et, yoksa otomatik oluştur
        let facilityId;
        const facCheck = await db.query('SELECT id FROM facilities WHERE owner_id = $1 LIMIT 1', [parsedOwnerId]);

        if (facCheck.rows.length > 0) {
            facilityId = facCheck.rows[0].id;
        } else {
            console.log('Tesis bulunamadı, yeni bir tesis oluşturuluyor ownerId: ' + parsedOwnerId);
            const facInsert = await db.query(`
                INSERT INTO facilities (name, owner_id, district, address, latitude, longitude) 
                VALUES ('Tesis', $1, $2, $3, 41.0082, 28.9784) RETURNING id
            `, [parsedOwnerId, district || 'Girilen İlçe', address || 'Girilen Adres']);
            facilityId = facInsert.rows[0].id;
        }

        // Sahayı pitch tablosuna ekle
        const finalInsert = await db.query(`
            INSERT INTO pitches (
                facility_id, name, type, capacity, hourly_price, deposit_price, 
                opening_hour, closing_hour, slot_duration, is_active
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true) RETURNING *
        `, [
            facilityId, name || 'Yeni Saha', type || 'Açık', capacity || 14, hourlyPrice || 1500, depositPrice || 0,
            openingHour || 8, closingHour || 23, slotDuration || 60
        ]);

        console.log("Yeni saha başarıyla eklendi: ", finalInsert.rows[0]);
        res.status(201).json({ success: true, data: finalInsert.rows[0] });

    } catch (error) {
        console.error('Yeni Saha Ekleme Hatası (DB INSERT):', error);
        res.status(500).json({ success: false, error: 'Database Hatası: ' + error.message });
    }
});

// --- SAHA FİYAT GÜNCELLE ---
router.put('/:pitchId', authMiddleware, roleMiddleware('isletme', 'admin', 'sahasahibi'), async (req, res) => {
    try {
        const { pitchId } = req.params;
        const updatePrice = req.body.hourlyPrice || req.body.price || req.body.hourly_price;
        const waterPrice = req.body.water_price;
        const cleatsPrice = req.body.cleats_price;
        const glovesPrice = req.body.gloves_price;

        console.log(`[PITCH UPDATE REQUEST] PitchID: ${pitchId} | Price: ${updatePrice} | Water: ${waterPrice} | Cleats: ${cleatsPrice} | Gloves: ${glovesPrice}`);

        if (!updatePrice) {
            return res.status(400).json({ success: false, error: 'Fiyat bilgisi eksik (hourlyPrice veya price)' });
        }

        const resUpdate = await db.query(`
            UPDATE pitches 
            SET hourly_price = $1, 
                water_price = COALESCE($2, water_price), 
                cleats_price = COALESCE($3, cleats_price), 
                gloves_price = COALESCE($4, gloves_price), 
                updated_at = NOW() 
            WHERE id = $5 RETURNING *
        `, [updatePrice, waterPrice, cleatsPrice, glovesPrice, pitchId]);

        if (resUpdate.rows.length === 0) {
            return res.status(404).json({ success: false, error: 'Saha bulunamadı' });
        }

        res.json({ success: true, data: resUpdate.rows[0] });
    } catch (error) {
        console.error('Saha Güncelleme Hatası:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// --- GÖRSEL YÜKLEME VE GÜNCELLEME ---
router.post('/:pitchId/image', authMiddleware, roleMiddleware('isletme', 'admin', 'sahasahibi', 'Admin', 'SahaSahibi'), upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, error: 'Lütfen bir görsel seçin.' });
        }

        const { pitchId } = req.params;
        const imageUrl = 'uploads/pitches/' + req.file.filename;

        // Sahaya ait facility_id'yi bul
        const pitchCheck = await db.query('SELECT facility_id FROM pitches WHERE id = $1', [pitchId]);

        if (pitchCheck.rows.length === 0) {
            return res.status(404).json({ success: false, error: 'Saha bulunamadı.' });
        }

        const facilityId = pitchCheck.rows[0].facility_id;

        // Eğer tesis yoksa hata dön
        if (!facilityId) {
            return res.status(404).json({ success: false, error: 'Sahaya ait tesis bulunamadı.' });
        }

        // Tesis tablosundaki image_url kolonunu güncelle
        await db.query('UPDATE facilities SET image_url = $1 WHERE id = $2', [imageUrl, facilityId]);

        res.status(200).json({
            success: true,
            message: 'Görsel başarıyla güncellendi',
            imageUrl: imageUrl
        });

    } catch (error) {
        console.error('Saha Görsel Yükleme Hatası:', error);
        res.status(500).json({ success: false, error: 'Görsel yüklenirken sunucu hatası.' });
    }
});

module.exports = router;
