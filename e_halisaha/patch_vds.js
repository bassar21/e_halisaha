const { spawn } = require('child_process');

const patchCode = 
/**
 * @route   GET /api/bookings/facility/:pitchId
 * @desc    Belirli bir sahaya ait rezervasyonlari ceker
 */
router.get('/facility/:pitchId', authMiddleware, async (req, res) => {
    try {
        const { pitchId } = req.params;
        const result = await db.query(\
            SELECT b.id, b.start_time as "rezDate", EXTRACT(HOUR FROM b.start_time)::int as "rezHour", b.total_price, b.status, b.payment_method, b.notes as "note", u.full_name as user_name, u.phone as user_phone
            FROM bookings b
            LEFT JOIN users u ON b.user_id = u.id
            WHERE b.pitch_id = \\
            ORDER BY b.start_time ASC\, [pitchId]);
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Rezervasyonlari Getirme Hatasi (Facility):', error);
        res.status(500).json({ success: false, error: error.message });
    }
});
module.exports = router;
;

const escapedPatch = patchCode.replace(/'/g, "'\\\\''").replace(/"/g, '\\\\\\"');

const sshCommand = \ssh root@185.157.46.167 "node -e \\"const fs = require('fs'); const file = '/var/www/ehalisaha/backend/src/routes/bookingRoutes.js'; let content = fs.readFileSync(file, 'utf8'); content = content.replace('module.exports = router;', '\'); fs.writeFileSync(file, content);\\" && pm2 restart ehalisaha-backend"\;

const child = spawn(sshCommand, { shell: true });
child.stdout.on('data', (data) => console.log(data.toString()));
child.stderr.on('data', (data) => console.error(data.toString()));
