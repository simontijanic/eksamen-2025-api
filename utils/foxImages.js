// Hjelpefunksjoner for å generere og validere fox image IDs og URLs

const MAX_FOX_ID = 123;
const FOX_IMAGE_BASE_URL = process.env.FOX_IMAGE_BASE_URL || 'https://randomfox.ca/images/';

function getRandomFoxId(excludeId = null) {
    let id;
    do {
        id = Math.floor(Math.random() * MAX_FOX_ID) + 1;
    } while (id === excludeId);
    return id;
}

function getFoxImageUrl(id) {
    return `${FOX_IMAGE_BASE_URL}${id}.jpg`; // Genererer URL for fox-bilde
}

module.exports = {
    MAX_FOX_ID,
    getRandomFoxId,
    getFoxImageUrl
};
