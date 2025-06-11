module.exports = {
    apps: [
        {
            name: 'foxvote-api',
            script: 'index.js',
            env: {
                NODE_ENV: 'production',
                PORT: 3000,
                MONGODB_URI: process.env.MONGODB_URI,
                FOX_IMAGE_BASE_URL: process.env.FOX_IMAGE_BASE_URL || 'https://randomfox.ca/images/'
            }
        }
    ]
}