from .models import ProductionJob, ProductionStatus
from .router import choose_engine, validate_job

class ProviderAdapter:
    name = "base"
    def generate_shot(self, shot: dict, job: ProductionJob) -> dict:
        raise NotImplementedError

class ProductionWorker:
    def __init__(self, adapters: dict[str, ProviderAdapter]):
        self.adapters = adapters

    def process(self, job: ProductionJob, requested_engine: str | None = None) -> dict:
        validate_job(job)
        engine = choose_engine(job.production_type, job.target_minutes, requested_engine)
        adapter = self.adapters.get(engine)
        if adapter is None:
            raise RuntimeError(f"No adapter configured for {engine}")

        results = []
        for index, shot in enumerate(job.shots):
            # Cancellation should be checked against Firestore before each shot.
            result = adapter.generate_shot(shot, job)
            results.append({"index": index, "result": result})

        # Assembly/review/output storage are intentionally separate stages.
        return {"jobId": job.job_id, "engine": engine, "shots": results}
