from base import Base, engine, SessionLocal, User

Base.metadata.create_all(bind=engine)

session = SessionLocal()
users = [
    User(login='pavel', email='a@gmail.com', hashed_password='pavelhash'),
    User(login='yura', email='b@gmail.com', hashed_password='yurahash')
]
try:
    session.add_all(users)
    session.commit()
except:
    pass
session.close()
