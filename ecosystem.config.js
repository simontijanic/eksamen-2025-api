module.exports = {
    apps: [
        {
            name: 'joke-api',
            script: 'index.js',
            env: {
                NODE_ENV: 'production',
                PORT: 3000,
                MONGODB_URI: process.env.MONGODB_URI
            }
        }
    ]
}