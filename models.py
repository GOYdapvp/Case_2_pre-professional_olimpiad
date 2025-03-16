from sqlalchemy import Column, Integer, String, Float
from database import Base

class Tile(Base):
    __tablename__ = "tiles"
    id = Column(Integer, primary_key=True, index=True)
    data = Column(String)  # JSON string of the tile data

class Module(Base):
    __tablename__ = "modules"
    id = Column(Integer, primary_key=True, index=True)
    x = Column(Integer)
    y = Column(Integer)

class Station(Base):
    __tablename__ = "stations"
    id = Column(Integer, primary_key=True, index=True)
    type = Column(String)
    x = Column(Integer)
    y = Column(Integer)
    cost = Column(Float)
