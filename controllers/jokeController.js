const axios = require('axios');
const JokeReview = require('../models/jokeReview');

// Hent én tilfeldig vits fra ekstern API med axios
exports.getRandomJoke = async (req, res) => {
    try {
        const response = await axios.get(process.env.JOKEAPI);
        res.json(response.data);
    } catch (err) {
        res.status(500).json({ message: 'Kunne ikke hente vits.' });
    }
};

// Lagre en anmeldelse av en vits
exports.reviewJoke = async (req, res) => {
    const { jokeId, stars, comment } = req.body;
    if (!jokeId || !stars) return res.status(400).json({ message: 'jokeId og stars er påkrevd' });
    try {
        await JokeReview.create({ jokeId, stars, comment });
        // Finn ny gjennomsnittsrating
        const agg = await JokeReview.aggregate([
            { $match: { jokeId: Number(jokeId) } },
            { $group: { _id: '$jokeId', avg: { $avg: '$stars' }, count: { $sum: 1 } } }
        ]);
        const avg = agg[0] ? agg[0].avg : null;
        const count = agg[0] ? agg[0].count : 0;
        res.json({ message: 'Takk for anmeldelsen!', average: avg, count });
    } catch (err) {
        res.status(500).json({ message: 'Database-feil' });
    }
};

// Hent gjennomsnittsrating for en vits
exports.getJokeAverage = async (req, res) => {
    const jokeId = Number(req.params.jokeId);
    if (!jokeId) return res.status(400).json({ message: 'jokeId er påkrevd' });
    try {
        const agg = await JokeReview.aggregate([
            { $match: { jokeId } },
            { $group: { _id: '$jokeId', avg: { $avg: '$stars' }, count: { $sum: 1 } } }
        ]);
        const avg = agg[0] ? agg[0].avg : null;
        const count = agg[0] ? agg[0].count : 0;
        res.json({ average: avg, count });
    } catch (err) {
        res.status(500).json({ message: 'Database-feil' });
    }
};
