const express = require('express');
const db = require('../config/database');
const { authMiddleware } = require('../middleware/auth');
const router = express.Router();

/**
 * @route   GET /api/bookings/my
 * @desc    Giriþ yapmýþ kullanýcýnýn kendi rezervasyonlarýný getirir
 */
router.get('/my', authMiddleware, async (req, res) => {
    try {
        // Token'dan gelen kullanýcý ID'sini alýyoruz
        const userId = req.user.userId || req.user.id;
        console.log(`?? Kullanýcý ${userId} için rezervasyonlar sorgulanýyor...`);

        const result = await db.query(
            `SELECT 
                b.id, 
                b.start_time, 
                b.end_time, 
                b.total_price, 
                b.status,
                p.name as pitch_name,
                f.name as facility_name,
                f.address,
                f.district,
                f.city
             FROM bookings b
             LEFT JOIN pitches p ON b.pitch_id = p.id
             LEFT JOIN facilities f ON p.facility_id = f.id
             WHERE b.user_id = $1
             ORDER BY b.start_time DESC`,
            [userId]
        );

        console.log(`? Sorgu bitti, ${result.rows.length} adet kayýt dönüyor.`);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('?? Rezervasyon listeleme hatasý:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * @route   GET /api/bookings/check/:pitchId
 * @desc    Belirli bir saha ve tarih için dolu saatleri getirir
 */
router.get('/check/:pitchId', async (req, res) => {
    try {
        const { pitchId } = req.params;
        const { date } = req.query; 

        const result = await db.query(
            `SELECT EXTRACT(HOUR FROM start_time)::int as hour 
             FROM bookings 
             WHERE pitch_id = $1 
             AND start_time::date = $2::date 
             AND LOWER(status) NOT IN ('cancelled', 'rejected')`,
            [pitchId, date]
        );

        const busyHours = result.rows.map(row => row.hour);
        res.json({ success: true, busyHours: busyHours });
    } catch (error) {
        console.error('?? Doluluk kontrol hatasý:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * @route   POST /api/bookings
 * @desc    Yeni rezervasyon oluþturur
 */
router.post('/', authMiddleware, async (req, res) => {
    try {
        const { pitchId, startTime, endTime, paymentMethod } = req.body;
        const userId = req.user.userId || req.user.id;

        // Fiyatý sahadan çekiyoruz
        const pitchResult = await db.query("SELECT hourly_price FROM pitches WHERE id = $1", [pitchId]);
        if (pitchResult.rows.length === 0) return res.status(404).json({ error: "Saha bulunamadý" });
        
        const totalPrice = pitchResult.rows[0].hourly_price;

        const result = await db.query(
            `INSERT INTO bookings 
            (pitch_id, user_id, start_time, end_time, total_price, status, payment_method) 
            VALUES ($1, $2, $3, $4, $5, $6, $7) 
            RETURNING *`,
            [pitchId, userId, startTime, endTime, totalPrice, 'confirmed', paymentMethod || 'online']
        );                    
        
        console.log(`? Rezervasyon yapýldý. ID: ${result.rows[0].id}`);
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('?? Rezervasyon ekleme hatasý:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;