import os
from .adapters import HTTPProviderAdapter
from .worker import ProductionWorker

def build_worker() -> ProductionWorker:
    adapters = {}
    for engine, env_name in {
        "moneyPrinterTurbo":"MONEYPRINTERTURBO_BASE_URL",
        "skyReelsV3":"SKYREELS_BASE_URL",
        "skyReelsV2":"SKYREELS_BASE_URL",
        "ltx2":"LTX_BASE_URL",
        "wan":"WAN_BASE_URL",
        "hunyuan":"HUNYUAN_BASE_URL",
    }.items():
        url = os.getenv(env_name)
        if url:
            adapters[engine] = HTTPProviderAdapter(engine, url)
    return ProductionWorker(adapters)

if __name__ == "__main__":
    print("AUREN Production Worker scaffold ready")
