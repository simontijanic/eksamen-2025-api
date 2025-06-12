const axios = require('axios');
const JokeReview = require('../models/jokeReview');

// Hent en tilfeldig vits fra ekstern API med axios
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
    // Hent ut data fra requesten
    const { jokeId, stars, comment } = req.body;
    // Sjekk at jokeId og stars er med
    if (!jokeId || !stars) {
        res.status(400).json({ message: 'jokeId og stars er påkrevd' });
        return;
    }
    try {
        // Lagre anmeldelsen i databasen
        await JokeReview.create({ jokeId, stars, comment });
        // Hent alle anmeldelser for denne vitsen
        const reviews = await JokeReview.find({ jokeId: Number(jokeId) });
        // Regn ut gjennomsnitt og antall
        // Vi går gjennom alle anmeldelser (reviews) og legger sammen stjerner
        let sum = 0;
        for (let i = 0; i < reviews.length; i++) {
            sum = sum + reviews[i].stars; // Legger til stjerner fra hver anmeldelse
        }
        let count = reviews.length; // Teller hvor mange anmeldelser det er
        let avg = 0;
        if (count > 0) {
            avg = sum / count; // Deler summen på antall for å få gjennomsnitt
        }
        // Send svar tilbake til frontend
        res.json({ message: 'Takk for anmeldelsen!', average: avg, count: count });
    } catch (err) {
        res.status(500).json({ message: 'Database-feil' });
    }
};

// Hent gjennomsnittsrating for en vits
exports.getJokeAverage = async (req, res) => {
    // Hent ut jokeId fra URL
    const jokeId = Number(req.params.jokeId);
    if (!jokeId) {
        res.status(400).json({ message: 'jokeId er påkrevd' });
        return;
    }
    try {
        // Hent alle anmeldelser for denne vitsen
        const reviews = await JokeReview.find({ jokeId: jokeId });
        // Regn ut gjennomsnitt og antall
        // Vi går gjennom alle anmeldelser (reviews) og legger sammen stjerner
        let sum = 0;
        for (let i = 0; i < reviews.length; i++) {
            sum = sum + reviews[i].stars; // Legger til stjerner fra hver anmeldelse
        }
        let count = reviews.length; // Teller hvor mange anmeldelser det er
        let avg = 0;
        if (count > 0) {
            avg = sum / count; // Deler summen på antall for å få gjennomsnitt
        }
        // Send svar tilbake til frontend
        res.json({ average: avg, count: count });
    } catch (err) {
        res.status(500).json({ message: 'Database-feil' });
    }
};
