const Vote = require('../models/vote');
const { getRandomFoxId, getFoxImageUrl } = require('../utils/foxImages');

const COOLDOWN_MS = 3000; // 3 sekunder
const voteCooldowns = {}; // IP -> timestamp

// Hent to tilfeldige rever
exports.getRandomImages = async (req, res) => {
    const id1 = getRandomFoxId();
    const id2 = getRandomFoxId(id1);
    res.json({
        fox1: { id: id1.toString(), url: getFoxImageUrl(id1) },
        fox2: { id: id2.toString(), url: getFoxImageUrl(id2) }
    });
};

// Stem på en rev
exports.voteForFox = async (req, res) => {
    const { imageId } = req.body;
    if (!imageId) return res.status(400).json({ message: 'imageId is required' });

    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const now = Date.now();

    if (voteCooldowns[ip] && now - voteCooldowns[ip] < COOLDOWN_MS) {
        return res.status(429).json({ message: 'Vent litt før du stemmer igjen.' });
    }
    voteCooldowns[ip] = now;

    try {
        // Øk stemmetallet for valgt bilde
        const vote = await Vote.findOneAndUpdate(
            { imageId },
            { $inc: { votes: 1 } },
            { upsert: true, new: true }
        );
        res.json({ message: 'Stemme registrert', vote });
    } catch (err) {
        res.status(500).json({ message: 'Database-feil' });
    }
};

// Hent toppliste og leder
exports.getStats = async (req, res) => {
    try {
        const toplist = await Vote.find().sort({ votes: -1 }).limit(10);
        const leader = toplist[0] ? { imageId: toplist[0].imageId, votes: toplist[0].votes } : null;
        res.json({ leader, toplist });
    } catch (err) {
        res.status(500).json({ message: 'Database-feil' });
    }
};
