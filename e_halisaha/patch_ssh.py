import subprocess
import base64

patch_code = """
/**
 * @route   GET /api/bookings/facility/:pitchId
 * @desc    Belirli bir sahaya ait rezervasyonları çeker
 */
router.get('/facility/:pitchId', authMiddleware, async (req, res) => {
    try {
        const { pitchId } = req.params;
        const result = await db.query(
            `SELECT b.id, b.start_time as "rezDate", EXTRACT(HOUR FROM b.start_time)::int as "rezHour", b.total_price, b.status, b.payment_method, b.notes as "note", u.full_name as user_name, u.phone as user_phone FROM bookings b LEFT JOIN users u ON b.user_id = u.id WHERE b.pitch_id = $1 ORDER BY b.start_time ASC`,
            [pitchId]
        );
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Rezervasyonları Getirme Hatası (Facility):', error);
        res.status(500).json({ success: false, error: error.message });
    }
});
module.exports = router;
"""

b64_patch = base64.b64encode(patch_code.encode('utf-8')).decode('utf-8')

cmd = f"""ssh root@185.157.46.167 "python3 -c \\"
import base64
with open('/var/www/ehalisaha/backend/src/routes/bookingRoutes.js', 'r', encoding='utf-8') as f:
    content = f.read()

patch = base64.b64decode('{b64_patch}').decode('utf-8')
content = content.replace('module.exports = router;', patch)

with open('/var/www/ehalisaha/backend/src/routes/bookingRoutes.js', 'w', encoding='utf-8') as f:
    f.write(content)
\\" && pm2 restart ehalisaha-backend"
"""

print("Executing SSH Patch via Python...")
try:
    result = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    print(result.stdout)
except subprocess.CalledProcessError as e:
    print("Error:", e.stderr)
