-- 1. Tabla de Usuarios (autenticación y perfil)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    company VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    account_type VARCHAR(20) DEFAULT 'free' CHECK (account_type IN ('free', 'basic', 'premium')),
    trial_end_date TIMESTAMP,
    subscription_end_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar búsquedas
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_company ON users(company);

-- 2. Tabla de Corpus Histórico por Usuario
CREATE TABLE user_corpus (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de Verbatims en el Corpus
CREATE TABLE corpus_verbatims (
    id SERIAL PRIMARY KEY,
    corpus_id INTEGER NOT NULL REFERENCES user_corpus(id) ON DELETE CASCADE,
    response TEXT NOT NULL,
    cod_1 VARCHAR(50),
    cod_2 VARCHAR(50),
    cod_3 VARCHAR(50),
    cod_4 VARCHAR(50),
    cod_5 VARCHAR(50),
    embedding BYTEA,  -- Almacenamiento de embeddings (binario)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice GIN para búsquedas eficientes de texto
CREATE INDEX idx_corpus_verbatims_response ON corpus_verbatims USING GIN (to_tsvector('spanish', response));

-- 4. Tabla de Mapeo de Códigos a Descripciones
CREATE TABLE code_mappings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    code INTEGER NOT NULL,
    value TEXT NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, code)
);

-- 5. Tabla de Procesamientos
CREATE TABLE processing_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    corpus_id INTEGER REFERENCES user_corpus(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    input_file_path VARCHAR(512),
    output_file_path VARCHAR(512),
    total_records INTEGER NOT NULL,
    auto_processed INTEGER DEFAULT 0,
    optional_review INTEGER DEFAULT 0,
    mandatory_review INTEGER DEFAULT 0,
    invalid_records INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    processing_time FLOAT
);

-- 6. Tabla de Resultados Detallados
CREATE TABLE processing_results (
    id SERIAL PRIMARY KEY,
    job_id UUID NOT NULL REFERENCES processing_jobs(id) ON DELETE CASCADE,
    original_id VARCHAR(100) NOT NULL,
    response TEXT NOT NULL,
    cod_1 VARCHAR(50),
    cod_2 VARCHAR(50),
    cod_3 VARCHAR(50),
    cod_4 VARCHAR(50),
    cod_5 VARCHAR(50),
    value_1 TEXT,
    value_2 TEXT,
    value_3 TEXT,
    value_4 TEXT,
    value_5 TEXT,
    similarity_score FLOAT,
    confidence_gap FLOAT,
    code_consistency FLOAT,
    text_quality VARCHAR(50),
    review_level VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Tabla de Actividad de Usuarios
CREATE TABLE user_activity (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    description TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Tabla de Configuración por Usuario
CREATE TABLE user_settings (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    target_auto_processing FLOAT DEFAULT 0.85,
    min_similarity_threshold FLOAT DEFAULT 0.18,
    similarity_threshold FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Tabla de Logs del Sistema
CREATE TABLE system_logs (
    id SERIAL PRIMARY KEY,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    context JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Función para actualizar el timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar timestamps
CREATE TRIGGER update_users_modtime
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_user_corpus_modtime
BEFORE UPDATE ON user_corpus
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_corpus_verbatims_modtime
BEFORE UPDATE ON corpus_verbatims
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_code_mappings_modtime
BEFORE UPDATE ON code_mappings
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_user_settings_modtime
BEFORE UPDATE ON user_settings
FOR EACH ROW EXECUTE FUNCTION update_modified_column();



