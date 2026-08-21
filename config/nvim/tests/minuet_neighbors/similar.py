def resample_dataframe(df, window):
    resampled = df.resample(f"{window}min").mean()
    return resampled.ffill()


def clip_outliers(df, lower, upper):
    return df.clip(lower=lower, upper=upper)
# edited before :wq
