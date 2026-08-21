def process_sensor_data(df, window):
    resampled = df.resample(f"{window}min").mean()
    clipped =
