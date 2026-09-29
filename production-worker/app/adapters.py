class HTTPProviderAdapter:
    def __init__(self, name: str, base_url: str):
        self.name = name
        self.base_url = base_url.rstrip("/")

    def generate_shot(self, shot: dict, job) -> dict:
        # Implement provider-specific HTTP auth/request/retry here.
        # Keep credentials in environment variables on the worker.
        raise NotImplementedError(f"Configure {self.name} adapter at {self.base_url}")
