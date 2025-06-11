const Vote = require('../models/vote');
const { getRandomFoxId, getFoxImageUrl } = require('../utils/foxImages');

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
