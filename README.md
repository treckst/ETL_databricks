## Incremental Medallion Pipeline on Azure Databricks with Lakeflow Jobs

![](./screenshots/Untitled-scene.png)
### An end-to-end incremental data engineering pipeline processing Binance cryptocurrency trading events using PySpark Structured Streaming, Delta Lake, Databricks Lakeflow Jobs, and Terraform.

### "Streaming-as-Batch" via Lakeflow Jobs
Configured Databricks Lakeflow Jobs to trigger PySpark Structured Streaming tasks on a 5-minute schedule using `.trigger(availableNow=True)`
Avoids the high infrastructure cost of running 24/7 compute clusters for intermittent file arrival. Spark processes all pending micro-batches incrementally, commits checkpoints, and cleanly terminates the compute.

### Reliable Incremental Ingestion (Auto Loader)
Ingested raw trade dumps from Azure Data Lake Storage Gen2 using Databricks Auto Loader `.format("cloudFiles")`.

Auto Loader detects new files asynchronously without expensive recursive directory listings. Corrupted or non-conforming rows are automatically isolated into the `_rescued_data` column rather than failing the stream, ensuring zero data loss and strict schema enforcement.

### Stateful Aggregations & Watermarking
Applied a 10-minute watermark on event timestamps combined with a 10-minute tumbling window grouped by trading side (buy/sell).
Allows processing out-of-order and late-arriving trade events. Once the event time surpasses the watermark boundary, Spark finalizes the state and evicts old aggregation windows from memory, preventing state store unbounded growth. 

### Tolerance & Idempotent Delta Upserts
Implementation: Managed streaming offsets and RocksDB state storage using Unity Catalog checkpoint Volumes (bronze_checkpoints, silver_checkpoints, gold_checkpoints).
Stream writes to the Gold layer use `outputMode("update")` with `foreachBatch` running an atomic Delta MERGE `whenMatchedUpdateAll` & `whenNotMatchedInsertAll` to update the exists states/new ones without reprocessing the whole sink on each trigger.
Checkpoints ensure that failed jobs resume from the exact failure offset without reprocessing history=. The MERGE operation makes micro-batch writes fully idempotent, eliminating duplicate rows during task retries or pipeline re-runs.
 


### Security & Governance
Access to Azure Data Lake Storage Gen2 is entirely keyless and centrally governed through Databricks Unity Catalog:
Azure Managed Identity eliminates hardcoded keys and SAS tokens.
Unity Catalog mediates secure, governed access to ADLS containers with granular role-based permissions.
![](./screenshots/managed_identity.jpg)
![](./screenshots/credential.jpg)
![](./screenshots/external_location.jpg)
![](/screenshots/catalog.png)

### Orchestration & Pipeline Monitoring
Scheduled using Databricks Lakeflow Jobs to coordinate execution across the Bronze, Silver, and Gold pipelines
![](./screenshots/lakeflow_job.jpg)
![](/screenshots/job_runs.png)

### Medallion Layers
#### Bronze:
*Auto Loader is ingesting new raw CSV from the ADLS, rate limiting `(maxFilesPerTrigger=500)`, and `_rescued_data` to capturea malforwed data*
![](./screenshots/bronze_layer.jpg)

#### Silver:
*Type casting (LongType, DecimalType). Converted 13-digit Unix timestamps  to UTC TimestampType using timestamp_millis(), dropping raw metadata column, calculating order_amount, and partitioning time attributes (date, hour, minute, second)*
![](./screenshots/silver_layer.png)

#### Gold:
*10-minute event-time watermarking, windowed trade volume aggregations, and idempotent upserts via `foreachBatch` and Delta MERGE with Delta API*
![](./screenshots/gold_layer.png)

### Source of dataset: https://www.kaggle.com/datasets/circeukan/binance-trading-events?utm_source=chatgpt.com&select=btcusdt.spot.trades.csv

