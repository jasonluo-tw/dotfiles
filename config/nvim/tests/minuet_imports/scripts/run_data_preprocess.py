import pandas as pd


@dataclass
class Config:
    """Holds preprocessing knobs."""
    window: int


def run_pipeline(df: pd.DataFrame, window: int = 30) -> pd.DataFrame:
    """Resample df to `window`-minute bins and forward-fill gaps.

    Args:
        df: raw sensor readings, indexed by timestamp.
        window: bin size in minutes.
    Returns:
        Resampled dataframe with the same columns as df.
    """
    return df.resample(f'{window}min').mean().ffill()
