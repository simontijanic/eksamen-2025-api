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

    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress; // x-forwarded-for for proxyer, ellers direkte IP
    // hvis serveren står bak en proxy som nginx bil brukerens ip ligge i http headeren x-forwarded-for hvis ikke så bruker vi direkte ip fra socketen
    const now = Date.now();

    if (voteCooldowns[ip] && now - voteCooldowns[ip] < COOLDOWN_MS) {
        return res.status(429).json({ message: 'Vent litt før du stemmer igjen.' });
    }
    voteCooldowns[ip] = now;

    try {
        // Øk stemmetallet for valgt bilde
        const vote = await Vote.findOneAndUpdate(
            { imageId },
            { $inc: { votes: 1 } }, // $inc øker stemmetallet med 1
            { upsert: true, new: true } // Opprett hvis ikke eksisterer, returner ny stemme
        );
        res.json({ message: 'Stemme registrert', vote });
    } catch (err) {
        res.status(500).json({ message: 'Database-feil' });
    }
};

// Hent toppliste og leder
exports.getStats = async (req, res) => {
    try {
        const toplist = await Vote.find().sort({ votes: -1 }).limit(10); // Hent topp 10 rever sortert etter stemmer
        const leader = toplist[0] ? { imageId: toplist[0].imageId, votes: toplist[0].votes } : null; 
        // hvis toplist finnes settes leader til et objekt med bilde id, og antall stemmer, og hvis ingen har stemt settes leader til null
        res.json({ leader, toplist });
    } catch (err) {
        res.status(500).json({ message: 'Database-feil' });
    }
};
