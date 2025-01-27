-- тип продукта (хлеб/рыба/т.д.)
CREATE TABLE product_types (
    id SERIAL PRIMARY KEY, -- id типа продукта
    name VARCHAR(50) NOT NULL UNIQUE -- название
);

-- единицы измерения
CREATE TABLE units (
    id SERIAL PRIMARY KEY, -- id единицы измерения
    name VARCHAR(50) NOT NULL UNIQUE -- название (и всё)
);

CREATE TABLE main (
    id SERIAL PRIMARY KEY, -- id продукта
    name VARCHAR(100) NOT NULL, -- название продукта
    type_id INT NOT NULL REFERENCES product_types(id) ON DELETE CASCADE, -- id типа продукта
    manufacture_date DATE NOT NULL, -- дата создания сие великого продукта России матушки
    expiration_date DATE NOT NULL, -- дата истечения срока годнисти сие милосердной ценности
    quantity NUMERIC(10, 2) NOT NULL CHECK (quantity >= 0), -- кол-во
    nutritional_info NUMERIC(10, 2) NOT NULL CHECK (nutritional_info >= 0), -- пищевая ценность
    unit_id INT NOT NULL REFERENCES units(id) ON DELETE CASCADE -- id единиц измерения
    CHECK (manufacture_date <= expiration_date) -- нужно для случаев ошибки данных (продукт испорчен до создания)
);
