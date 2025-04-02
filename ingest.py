import json
import pathlib

import click
from pypgstac.db import PgstacDB
from pypgstac.load import Loader, Methods


def open_jsonl(path):
    with open(path) as f:
        return [json.loads(line.strip()) for line in f]


@click.command()
@click.argument("root", type=click.Path(readable=True, path_type=pathlib.Path))
def main(root):
    method = Methods.upsert
    db = PgstacDB(dsn="", debug=False)
    loader = Loader(db=db)

    collections = open_jsonl(root.joinpath("collections.jsonl"))
    loader.load_collections(collections, method)

    items = open_jsonl(root.joinpath("items.jsonl"))
    loader.load_items(items, method, dehydrated=False, chunksize=10000)


if __name__ == "__main__":
    main()
