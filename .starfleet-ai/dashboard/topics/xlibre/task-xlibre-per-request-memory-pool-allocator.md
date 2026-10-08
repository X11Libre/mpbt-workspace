Title: "xlibre: per-request memory pool allocator"
Category: xlibre
Kind: task
Status: "open"
Created-By: "McKinley"
Created: "2026-10-08T16:03:28Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: xlibre/task-xlibre-per-request-memory-pool-allocator

1. add a generic pool allocator:
--> put it into os/ subdir -> new source and header files
--> main data structure is a zero-initialized struct
--> tracks all allocated chunks in a list/array/...
--> operations:
  * void *xlibre_pool_alloc(x_mempool_t *pool, size_t size)  --> allocate size bytes (NULL on error) and clear the region (eg. via calloc or malloc+memset)
  * void xlibre_pool_destroy(x_mempool_t *pool)
    --> destroy the whole pool, along with all allocated chunks
    --> clear out the struct, so it's unitialized again (zero-init approach)

2. add an x_mempool_t to ClientRec (at the end, mark it as private)  
--> serves as per-request pool
--> clear it again when finished processing a request (and before going to the next one)

3. step by step check which places could make use of it.
   --> those only allocate (and check the result)
   --> but don't need to free again, because that's now done in a central place. 
   --> careful: only use the per-request allocator for data that's guaranteed to be unused after the request is processed (don't pass pointers to anywhere else!)
