from flask import Flask
from app import config, db


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.from_mapping(DATABASE=config.DATABASE, EXPORT_DIR=config.EXPORT_DIR)
    if test_config:
        app.config.update(test_config)

    from app import exports, reviews, users
    app.register_blueprint(reviews.bp)
    app.register_blueprint(users.bp)
    app.register_blueprint(exports.bp)
    app.teardown_appcontext(db.close_db)
    app.cli.add_command(db.init_db_command)
    return app
