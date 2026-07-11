from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
    'DATABASE_URL', 'postgresql://postgres:postgres@db:5432/notesdb'
)
db = SQLAlchemy(app)

class Note(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.Text, nullable=False)

    def to_dict(self):
        return {"id": self.id, "title": self.title, "content": self.content}

@app.route('/notes', methods=['GET'])
def get_notes():
    notes = Note.query.all()
    return jsonify([n.to_dict() for n in notes])

@app.route('/notes', methods=['POST'])
def create_note():
    data = request.get_json()
    note = Note(title=data['title'], content=data['content'])
    db.session.add(note)
    db.session.commit()
    return jsonify(note.to_dict()), 201

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

with app.app_context():
     db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
