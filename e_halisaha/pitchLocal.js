const express = require('express');
const db = require('../config/database');
const { authMiddleware, roleMiddleware } = require('../middleware/auth');

const router = express.Router();

// --- TÜM SAHALARI TESÝS BÝLGÝLERÝYLE GETÝR ---
router.get('/', async (req, res) => {
    try {
        const result = await db.query(`
      SELECT 
        p.id, 
        p.name, 
        p.hourly_price as price, 
        p.deposit_price as deposit, 
        p.type,
        p.capacity,
        f.address, 
        f.district,
        f.city,
        f.image_url,
        f.owner_id,
        u.email as owner_email
      FROM pitches p
      LEFT JOIN facilities f ON p.facility_id = f.id
      LEFT JOIN users u ON f.owner_id = u.id
      WHERE p.is_active = true
      ORDER BY p.created_at DESC
    `);

        res.json({ success: true, count: result.rows.length, data: result.rows });
    } catch (error) {
        console.error('Saha listeleme hatasý:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// --- YENÝ SAHA EKLE ---
router.post('/', authMiddleware, roleMiddleware('SahaSahibi', 'Admin', 'isletme'), async (req, res) => {
    try {
        const {
            name, type, capacity, hourlyPrice, depositPrice,
            openingHour, closingHour, slotDuration, district, address, ownerId
        } = req.body;

        const uId = req.user.userId;

        let userFacility = await db.query('SELECT id FROM facilities WHERE owner_id = $1 LIMIT 1', [uId]);
        let fId;

        if (userFacility.rows.length === 0) {
            const insertFacility = await db.query(
                'INSERT INTO facilities (name, owner_id, district, address) VALUES ($1, $2, $3, $4) RETURNING id',
                [name + " Tesisleri", uId, district || 'Merkez', address || 'Girilen adres yok']
            );
            fId = insertFacility.rows[0].id;
        } else {
            fId = userFacility.rows[0].id;
        }

        const result = await db.query(
            `INSERT INTO pitches 
       (facility_id, name, type, capacity, hourly_price, deposit_price, 
        opening_hour, closing_hour, slot_duration, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true)
       RETURNING *`,
            [fId, name, type || 'Açýk', capacity || 14, hourlyPrice || 1500, depositPrice || 0,
                openingHour || 8, closingHour || 23, slotDuration || 60]
        );
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('Saha Eklerken Hata:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// --- SAHA GÜNCELLE ---
router.put('/:pitchId', authMiddleware, roleMiddleware('SahaSahibi', 'Admin', 'isletme'), async (req, res) => {
    try {
        const { pitchId } = req.params;
        const price = req.body.hourlyPrice || req.body.price;

        const result = await db.query(
            `UPDATE pitches 
       SET hourly_price = COALESCE($1, hourly_price), updated_at = NOW()
       WHERE id = $2 RETURNING *`,
            [price, pitchId]
        );
        res.json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('Saha Güncelleme Hatasý:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;
