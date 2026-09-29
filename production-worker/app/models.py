from dataclasses import dataclass, field
from enum import Enum
from typing import Any

class ProductionStatus(str, Enum):
    QUEUED="queued"; PLANNING="planning"; GENERATING="generating"
    ASSEMBLING="assembling"; REVIEW="review"; COMPLETED="completed"
    FAILED="failed"; CANCELLED="cancelled"

@dataclass
class ProductionJob:
    job_id: str
    uid: str
    title: str
    production_type: str
    target_minutes: int
    engine: str
    story_bible: dict[str, Any] = field(default_factory=dict)
    script: str = ""
    shots: list[dict[str, Any]] = field(default_factory=list)
