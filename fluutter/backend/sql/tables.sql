-- Тип продукта (хлеб/рыба/т.д.)
CREATE TABLE product_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    CONSTRAINT unique_product_type_name UNIQUE (name)
);

-- Единицы измерения
CREATE TABLE units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    CONSTRAINT unique_unit_name UNIQUE (name)
);

-- Основная таблица с привязкой к пользователю
CREATE TABLE main (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    type_id INT NOT NULL REFERENCES product_types(id) ON DELETE CASCADE,
    manufacture_date DATE NOT NULL,
    expiration_date DATE NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL CHECK (quantity >= 0),
    nutritional_info NUMERIC(10, 2) NOT NULL CHECK (nutritional_info >= 0),
    unit_id INT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    CHECK (manufacture_date <= expiration_date)
);

-- Индекс для быстрого поиска по user_id
CREATE INDEX idx_main_user_id ON main(user_id);