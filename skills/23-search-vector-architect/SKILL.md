---
name: search-vector-architect
description: Use this for implementing full-text search (Elasticsearch/OpenSearch) or vector search/embeddings (RAG, Pinecone, Chroma) for AI applications.
---

# Search & Vector Architect

You implement fast, accurate search and retrieval systems for both text and AI embeddings.

## When to use

- "Implement a search bar for this product."
- "Set up Elasticsearch."
- "Add vector search to this app."
- "Create a RAG pipeline."

## Instructions

1. Search Engines (Elasticsearch/OpenSearch):
   - Define mappings and analyzers (tokenizers, filters) for text relevance.
   - Optimize queries for performance (filtering vs. scoring).
2. Vector Search (Pinecone, Chroma, pgvector):
   - Define embedding models (OpenAI, HuggingFace) to use.
   - Design schema for metadata filtering (e.g., "search documents by year AND vector similarity").
3. Hybrid Search:
   - Combine keyword (BM25) and vector (semantic) search for best results.
4. RAG (Retrieval Augmented Generation):
   - Chunk documents optimally before embedding.
   - Retrieve top-k chunks and feed them as context to LLMs.

## Examples

### 1. Elasticsearch Full-Text Search Setup

```python
from elasticsearch import Elasticsearch

# Initialize client
es = Elasticsearch(['http://localhost:9200'])

# Create index with custom mappings
index_mapping = {
    "mappings": {
        "properties": {
            "title": {
                "type": "text",
                "analyzer": "english"
            },
            "description": {
                "type": "text",
                "analyzer": "english"
            },
            "category": {
                "type": "keyword"
            },
            "price": {
                "type": "float"
            },
            "created_at": {
                "type": "date"
            }
        }
    }
}

es.indices.create(index='products', body=index_mapping)

# Index a document
doc = {
    "title": "Wireless Headphones",
    "description": "High-quality noise-cancelling wireless headphones",
    "category": "electronics",
    "price": 199.99,
    "created_at": "2024-01-15"
}
es.index(index='products', id=1, body=doc)

# Search with filters
query = {
    "query": {
        "bool": {
            "must": [
                {"match": {"description": "wireless headphones"}}
            ],
            "filter": [
                {"term": {"category": "electronics"}},
                {"range": {"price": {"lte": 250}}}
            ]
        }
    }
}

results = es.search(index='products', body=query)
for hit in results['hits']['hits']:
    print(f"{hit['_source']['title']}: ${hit['_source']['price']}")
```

### 2. Vector Search with Pinecone

```python
import pinecone
from openai import OpenAI

# Initialize
pinecone.init(api_key='your-api-key', environment='us-west1-gcp')
openai_client = OpenAI(api_key='your-openai-key')

# Create index
index_name = 'product-embeddings'
if index_name not in pinecone.list_indexes():
    pinecone.create_index(
        name=index_name,
        dimension=1536,  # OpenAI embedding dimension
        metric='cosine'
    )

index = pinecone.Index(index_name)

# Generate embedding and upsert
def embed_text(text):
    response = openai_client.embeddings.create(
        model="text-embedding-ada-002",
        input=text
    )
    return response.data[0].embedding

# Add documents
documents = [
    {"id": "prod-1", "text": "Wireless noise-cancelling headphones", "category": "electronics"},
    {"id": "prod-2", "text": "Ergonomic office chair", "category": "furniture"},
]

vectors = []
for doc in documents:
    embedding = embed_text(doc['text'])
    vectors.append((doc['id'], embedding, {"category": doc['category'], "text": doc['text']}))

index.upsert(vectors=vectors)

# Search
query = "headphones for music"
query_embedding = embed_text(query)

results = index.query(
    vector=query_embedding,
    top_k=3,
    include_metadata=True,
    filter={"category": {"$eq": "electronics"}}
)

for match in results['matches']:
    print(f"Score: {match['score']:.3f} - {match['metadata']['text']}")
```

### 3. RAG Pipeline with Document Chunking

```python
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.chat_models import ChatOpenAI
from langchain.chains import RetrievalQA

# Load and chunk documents
with open('documentation.txt', 'r') as f:
    document = f.read()

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    length_function=len,
)

chunks = text_splitter.split_text(document)
print(f"Split into {len(chunks)} chunks")

# Create embeddings and vector store
embeddings = OpenAIEmbeddings()
vectorstore = Chroma.from_texts(
    texts=chunks,
    embedding=embeddings,
    persist_directory="./chroma_db"
)

# Create RAG chain
llm = ChatOpenAI(model_name="gpt-4", temperature=0)
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=vectorstore.as_retriever(search_kwargs={"k": 3}),
    return_source_documents=True
)

# Query
query = "How do I reset my password?"
result = qa_chain({"query": query})

print(f"Answer: {result['result']}")
print(f"\nSources:")
for i, doc in enumerate(result['source_documents'], 1):
    print(f"{i}. {doc.page_content[:100]}...")
```

### 4. Hybrid Search (Keyword + Semantic)

```python
from elasticsearch import Elasticsearch
import openai

es = Elasticsearch(['http://localhost:9200'])

def hybrid_search(query, index='documents'):
    # Get semantic embedding
    embedding = openai.Embedding.create(
        model="text-embedding-ada-002",
        input=query
    )['data'][0]['embedding']

    # Hybrid query combining BM25 and vector search
    search_query = {
        "query": {
            "bool": {
                "should": [
                    # Keyword search (BM25)
                    {
                        "multi_match": {
                            "query": query,
                            "fields": ["title^2", "content"],
                            "type": "best_fields"
                        }
                    },
                    # Vector search
                    {
                        "script_score": {
                            "query": {"match_all": {}},
                            "script": {
                                "source": "cosineSimilarity(params.query_vector, 'embedding') + 1.0",
                                "params": {"query_vector": embedding}
                            }
                        }
                    }
                ]
            }
        }
    }

    results = es.search(index=index, body=search_query, size=10)
    return results['hits']['hits']
```
