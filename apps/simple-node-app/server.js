// apps/simple-node-app/server.js
const http = require('http');
const url = require('url');

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const path = parsedUrl.pathname;
    const method = req.method;

    // Log della richiesta (verrà catturato da Docker logging)
    console.log(`${new Date().toISOString()} - ${method} ${path} - ${req.headers['user-agent']}`);

    // Aggiungi headers CORS e di debug
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    res.setHeader('X-Service', 'node-app3');

    // Routing semplice
    if (path === '/' || path === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            service: 'Node.js App 3',
            status: 'healthy',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            version: process.version,
            environment: process.env.NODE_ENV || 'development'
        }));
    }
    else if (path === '/slow') {
        // Endpoint che simula lentezza
        setTimeout(() => {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
                service: 'Node.js App 3',
                message: 'Slow response after 2 seconds',
                timestamp: new Date().toISOString()
            }));
        }, 2000);
    }
    else if (path === '/error') {
        // Endpoint che simula errore
        console.error(`${new Date().toISOString()} - ERROR: Simulated error endpoint accessed`);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            error: 'Simulated server error',
            timestamp: new Date().toISOString(),
            path: path
        }));
    }
    else if (path === '/memory') {
        // Endpoint per informazioni memoria
        const memUsage = process.memoryUsage();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            service: 'Node.js App 3',
            memory: {
                rss: `${Math.round(memUsage.rss / 1024 / 1024)} MB`,
                heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)} MB`,
                heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)} MB`,
                external: `${Math.round(memUsage.external / 1024 / 1024)} MB`
            },
            timestamp: new Date().toISOString()
        }));
    }
    else if (method === 'POST' && path === '/log') {
        // Endpoint per ricevere log personalizzati
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString();
        });
        req.on('end', () => {
            try {
                const logData = JSON.parse(body);
                console.log(`${new Date().toISOString()} - CUSTOM LOG:`, JSON.stringify(logData));
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    message: 'Log received',
                    timestamp: new Date().toISOString()
                }));
            } catch (error) {
                console.error(`${new Date().toISOString()} - ERROR parsing custom log:`, error.message);
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    error: 'Invalid JSON',
                    timestamp: new Date().toISOString()
                }));
            }
        });
    }
    else {
        // 404 per path non trovati
        console.log(`${new Date().toISOString()} - 404: ${path} not found`);
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            error: 'Not Found',
            path: path,
            timestamp: new Date().toISOString(),
            availableEndpoints: ['/', '/health', '/slow', '/error', '/memory', 'POST /log']
        }));
    }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`${new Date().toISOString()} - Node.js server started on port ${PORT}`);
    console.log(`${new Date().toISOString()} - Available endpoints:`);
    console.log(`  - GET  /        : Service info`);
    console.log(`  - GET  /health  : Health check`);
    console.log(`  - GET  /slow    : Slow response (2s)`);
    console.log(`  - GET  /error   : Simulated error`);
    console.log(`  - GET  /memory  : Memory usage`);
    console.log(`  - POST /log     : Custom log endpoint`);
});

// Gestione graceful shutdown
process.on('SIGTERM', () => {
    console.log(`${new Date().toISOString()} - SIGTERM received, shutting down gracefully`);
    server.close(() => {
        console.log(`${new Date().toISOString()} - Server closed`);
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log(`${new Date().toISOString()} - SIGINT received, shutting down gracefully`);
    server.close(() => {
        console.log(`${new Date().toISOString()} - Server closed`);
        process.exit(0);
    });
});
