from .models import ProductionJob

LONG_FORM = {"skyReelsV3", "skyReelsV2", "ltx2", "wan", "hunyuan"}
SHORT_FORM = {"moneyPrinterTurbo"}

def choose_engine(production_type: str, target_minutes: int, requested: str | None = None) -> str:
    if requested and requested in LONG_FORM | SHORT_FORM:
        return requested
    if production_type == "short":
        return "moneyPrinterTurbo"
    if target_minutes >= 30:
        return "skyReelsV3"
    return "ltx2"

def validate_job(job: ProductionJob) -> None:
    if not job.job_id or not job.uid:
        raise ValueError("job_id and uid are required")
    if not 1 <= job.target_minutes <= 240:
        raise ValueError("target_minutes must be between 1 and 240")
    if job.production_type not in {"short", "film", "seriesEpisode"}:
        raise ValueError("unsupported production type")
