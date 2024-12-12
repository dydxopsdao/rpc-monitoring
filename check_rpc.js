const chromium = require('@sparticuz/chromium');
const puppeteer = require('puppeteer-core');
const axios = require('axios');

const PROVIDERS = {
  "dydx-ops-rpc.kingnodes.com": "kingnodes",
  "dydx-mainnet-full-rpc.public.blastapi.io": "blastapi",
  "dydx-dao-rpc.polkachu.com": "polkachu",
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
      requestCounts[providerName] = 0;
    }

    page.on('request', req => {
      const url = req.url();
      for (const [providerUrl, providerName] of Object.entries(PROVIDERS)) {
        if (url.includes(providerUrl)) {
          requestCounts[providerName] += 1;
        }
      }
    });

    console.log(`[${new Date().toISOString()}] Navigating to page`);
    await page.goto('https://dydx.trade/trade/ETH-USD', { waitUntil: 'domcontentloaded', timeout: 60000 });
    console.log(`[${new Date().toISOString()}] Page loaded, waiting for requests`);
    await new Promise(resolve => setTimeout(resolve, 10000));

    let rpcProviderFound = 'unknown';
    let maxRequests = 0;

    for (const [providerName, count] of Object.entries(requestCounts)) {
      console.log(`[${new Date().toISOString()}] Provider ${providerName} made ${count} requests`);
      if (count > maxRequests) {
        maxRequests = count;
        rpcProviderFound = providerName;
      }
    }

    console.log(`[${new Date().toISOString()}] Detected RPC Provider: ${rpcProviderFound}`);
    return rpcProviderFound;
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Error in checkRPCProvider:`, error);
    throw error;
  } finally {
    if (browser) {
      console.log(`[${new Date().toISOString()}] Closing browser`);
      await browser.close();
    }
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

    const detectedProvider = await checkRPCProvider();
    const detectedLatency = latencies[detectedProvider] || 'unknown';

    console.log(`[${new Date().toISOString()}] Region: ${region}, Detected RPC Provider: ${detectedProvider}, latency: ${detectedLatency}ms`);

    await axios.post(
      'https://http-intake.logs.ap1.datadoghq.com/v1/input',
      {
        message: `Region: ${region}, RPC provider: ${detectedProvider}, latency: ${detectedLatency}ms, latencies: ${JSON.stringify(latencies)}, block heights: ${JSON.stringify(blockHeights)}`,
        ddsource: "custom-checker",
        ddtags: `env:prod,provider:${detectedProvider},region:${region}`,
        region: region,
        provider: detectedProvider,
        latency_ms: detectedLatency,
        latencies: latencies,
        block_heights: blockHeights
      },
      {
        headers: {
          "Content-Type": "application/json",
          "DD-API-KEY": process.env.DD_API_KEY
        }
      }
    );

    return { status: "success" };
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Error in handler:`, error);
    return { status: 'error', message: error.message };
  }
};
