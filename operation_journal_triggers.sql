
-- Удаление базы данных (если необходимо)
-- DROP DATABASE fitness_center_db;

-- Таблица Журнала операций
CREATE TABLE operation_log (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    operation_type VARCHAR(10) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    operation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    table_name VARCHAR(100) NOT NULL
);

-- Журнальные таблицы
CREATE TABLE users_log (
    id BIGINT,
    name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    role VARCHAR(50),
    operation_id BIGINT REFERENCES operation_log(id)
);

CREATE TABLE trainers_log (
    id BIGINT,
    user_id BIGINT,
    specialty VARCHAR(255),
    operation_id BIGINT REFERENCES operation_log(id)
);

CREATE TABLE trainings_log (
    id BIGINT,
    trainer_id BIGINT,
    name VARCHAR(255),
    description VARCHAR(1000),
    capacity INT,
    duration INT,
    operation_id BIGINT REFERENCES operation_log(id)
);

CREATE TABLE reservations_log (
    id BIGINT,
    user_id BIGINT,
    training_id BIGINT,
    reserved_at TIMESTAMP,
    status VARCHAR(50),
    operation_id BIGINT REFERENCES operation_log(id)
);

-- Функции логирования
CREATE OR REPLACE FUNCTION log_users_changes() RETURNS TRIGGER AS $$
DECLARE
    op_id BIGINT;
BEGIN
    INSERT INTO operation_log (username, operation_type, table_name)
    VALUES (current_user, TG_OP, 'users') RETURNING id INTO op_id;
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO users_log SELECT OLD.*, op_id;
        RETURN OLD;
    ELSE
        INSERT INTO users_log SELECT NEW.*, op_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION log_trainers_changes() RETURNS TRIGGER AS $$
DECLARE op_id BIGINT;
BEGIN
    INSERT INTO operation_log (username, operation_type, table_name)
    VALUES (current_user, TG_OP, 'trainers') RETURNING id INTO op_id;
    IF TG_OP = 'DELETE' THEN
        INSERT INTO trainers_log SELECT OLD.*, op_id;
        RETURN OLD;
    ELSE
        INSERT INTO trainers_log SELECT NEW.*, op_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION log_trainings_changes() RETURNS TRIGGER AS $$
DECLARE op_id BIGINT;
BEGIN
    INSERT INTO operation_log (username, operation_type, table_name)
    VALUES (current_user, TG_OP, 'trainings') RETURNING id INTO op_id;
    IF TG_OP = 'DELETE' THEN
        INSERT INTO trainings_log SELECT OLD.*, op_id;
        RETURN OLD;
    ELSE
        INSERT INTO trainings_log SELECT NEW.*, op_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION log_reservations_changes() RETURNS TRIGGER AS $$
DECLARE op_id BIGINT;
BEGIN
    INSERT INTO operation_log (username, operation_type, table_name)
    VALUES (current_user, TG_OP, 'reservations') RETURNING id INTO op_id;
    IF TG_OP = 'DELETE' THEN
        INSERT INTO reservations_log SELECT OLD.*, op_id;
        RETURN OLD;
    ELSE
        INSERT INTO reservations_log SELECT NEW.*, op_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Триггеры
CREATE TRIGGER trg_users_changes
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION log_users_changes();

CREATE TRIGGER trg_trainers_changes
AFTER INSERT OR UPDATE OR DELETE ON trainers
FOR EACH ROW EXECUTE FUNCTION log_trainers_changes();

CREATE TRIGGER trg_trainings_changes
AFTER INSERT OR UPDATE OR DELETE ON trainings
FOR EACH ROW EXECUTE FUNCTION log_trainings_changes();

CREATE TRIGGER trg_reservations_changes
AFTER INSERT OR UPDATE OR DELETE ON reservations
FOR EACH ROW EXECUTE FUNCTION log_reservations_changes();
