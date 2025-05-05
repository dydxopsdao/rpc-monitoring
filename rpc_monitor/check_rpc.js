const chromium = require('@sparticuz/chromium');
const puppeteer = require('puppeteer-core');
const axios = require('axios');

const PROVIDERS = {
    "dydx-ops-rpc.kingnodes.com": "kingnodes",
    "dydx-dao-rpc.polkachu.com": "polkachu",
    "dydx-dao-rpc-new.polkachu.com": "polkachu-experimental",
    "dydx-dao-rpc.enigma-validator.com": "enigma"
};

async function pingProviders() {
    console.log(`[${new Date().toISOString()}] Starting pingProviders`);
    const latencies = {};
    const blockHeights = {};

    for (const [providerUrl, providerName] of Object.entries(PROVIDERS)) {
        console.log(`[${new Date().toISOString()}] Pinging provider: ${providerUrl}`);
        const start = Date.now();
        try {
            const response = await axios.post(
                `https://${providerUrl}`,
                {
                    jsonrpc: "2.0",
                    id: 1,
                    method: "status",
                    params: {}
                },
                { timeout: 5000 }
            );
            const latency = Date.now() - start;
            latencies[providerName] = latency;
            blockHeights[providerName] = response.data?.result?.sync_info?.latest_block_height || 'unknown';
            console.log(`[${new Date().toISOString()}] Provider ${providerName} responded in ${latency}ms with block height ${blockHeights[providerName]}`);
        } catch (err) {
            latencies[providerName] = 'unreachable';
            blockHeights[providerName] = 'unreachable';
            console.error(`[${new Date().toISOString()}] Error pinging provider ${providerName}:`, err.message);
            
            // Log error to datadog on ping failure
              await logToDatadog(`Error pinging provider ${providerName}: ${err.message}`, 'error',  process.env.AWS_REGION || 'unknown', 'ping_error', null, null, null, null, null, null);
        }
    }

    console.log(`[${new Date().toISOString()}] Finished pingProviders`);
    return { latencies, blockHeights };
}


async function checkRPCProvider() {
    let browser;
    console.log(`[${new Date().toISOString()}] Starting checkRPCProvider`);
    try {
        browser = await puppeteer.launch({
            args: chromium.args,
            executablePath: await chromium.executablePath(),
            headless: true, // Always true for Lambda
            ignoreHTTPSErrors: true,
        });

        const page = await browser.newPage();
        console.log(`[${new Date().toISOString()}] Browser launched and new page created`);

        const requestCounts = {};
        for (const providerName of Object.values(PROVIDERS)) {
            requestCounts[providerName] = [];
        }

        page.on('request', req => {
            const url = req.url();
            const timestamp = Date.now();
            for (const [providerUrl, providerName] of Object.entries(PROVIDERS)) {
                if (url.includes(providerUrl)) {
                    requestCounts[providerName].push(timestamp);
                }
            }
        });

        console.log(`[${new Date().toISOString()}] Navigating to page`);
        await page.goto('https://dydx.trade/trade/ETH-USD', { waitUntil: 'domcontentloaded', timeout: 60000 });
        console.log(`[${new Date().toISOString()}] Page loaded, waiting for requests`);

        await new Promise(resolve => setTimeout(resolve, 20000)); 

        let rpcProviderFound = 'unknown';
        let maxRequests = 0;

        for (const [providerName, timestamps] of Object.entries(requestCounts)) {
             const requestCount = timestamps.length;
            console.log(`[${new Date().toISOString()}] Provider ${providerName} made ${requestCount} requests`);
             if (requestCount > maxRequests) {
                maxRequests = requestCount;
                rpcProviderFound = providerName;
             } else if (requestCount === maxRequests && requestCount > 0) {
             // If there is a tie, check the timestamps of the requests.
                 const existingProviderTimestamps = requestCounts[rpcProviderFound] || [];
            if (timestamps.length > 0 && existingProviderTimestamps.length > 0){
                const lastTimestampNew = Math.max(...timestamps);
                const lastTimestampExisting = Math.max(...existingProviderTimestamps);
                if (lastTimestampNew > lastTimestampExisting) {
                 rpcProviderFound = providerName;
                }
            }
           }
        }
        console.log(`[${new Date().toISOString()}] Detected RPC Provider: ${rpcProviderFound}`);
        return { rpcProviderFound, requestCounts };
    } catch (error) {
        console.error(`[${new Date().toISOString()}] Error in checkRPCProvider:`, error);
         // Log error to datadog on puppeteer failure
         await logToDatadog(`Error in checkRPCProvider: ${error.message}`, 'error', process.env.AWS_REGION || 'unknown', 'puppeteer_error', null, null, null, null, null, null)
        throw error;
    } finally {
        if (browser) {
            console.log(`[${new Date().toISOString()}] Closing browser`);
            await browser.close();
        }
    }
}

async function logToDatadog(message, level, region, source, provider, latency_ms, latencies, block_heights, request_counts,  requestId) {
   try {
    await axios.post(
            'https://http-intake.logs.ap1.datadoghq.com/v1/input',
            {
                message: message,
                ddsource: source,
                ddtags: `env:prod,region:${region}`,
                region: region,
                 provider: provider,
                latency_ms: latency_ms,
                latencies: latencies,
                 block_heights: block_heights,
                request_counts: request_counts,
                requestId: requestId
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    "DD-API-KEY": process.env.DD_API_KEY
                }
            }
        );
   } catch(e){
    console.error(`[${new Date().toISOString()}] Error sending to datadog:`, e.message)
   }
}



exports.handler = async function (event) {
    const region = process.env.AWS_REGION || 'unknown';
    const requestId = event?.requestContext?.requestId || 'unknown';
    console.log(`[${new Date().toISOString()}] Starting Lambda function with RequestId: ${requestId} in region: ${region}`);

    try {
        const { latencies, blockHeights } = await pingProviders();
        console.log(`[${new Date().toISOString()}] RPC Provider Latencies:`, latencies);
        console.log(`[${new Date().toISOString()}] RPC Provider Block Heights:`, blockHeights);

        const { rpcProviderFound, requestCounts } = await checkRPCProvider();
        const detectedLatency = latencies[rpcProviderFound] || 'unknown';
        
         const requestCountsForLog = {};
         for (const [providerName, timestamps] of Object.entries(requestCounts)) {
            requestCountsForLog[providerName] = timestamps.length;
         }

        console.log(`[${new Date().toISOString()}] Region: ${region}, Detected RPC Provider: ${rpcProviderFound}, latency: ${detectedLatency}ms`);
         
       
          await logToDatadog(`Region: ${region}, RPC provider: ${rpcProviderFound}, latency: ${detectedLatency}ms, latencies: ${JSON.stringify(latencies)}, block heights: ${JSON.stringify(blockHeights)}, request_counts: ${JSON.stringify(requestCountsForLog)}`,
                'info', region, "custom-checker", rpcProviderFound, detectedLatency, latencies, blockHeights, requestCountsForLog, requestId);

        return { status: "success" };
    } catch (error) {
        console.error(`[${new Date().toISOString()}] Error in handler:`, error);
        // Log error to datadog on lambda failure
        await logToDatadog(`Error in handler: ${error.message}`, 'error',  process.env.AWS_REGION || 'unknown', 'lambda_error', null, null, null, null, null, requestId);
        return { status: 'error', message: error.message };
    }
};