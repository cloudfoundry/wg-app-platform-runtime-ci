# Auction

This repository contains the source code for the Cloud Foundry package
responsible for the details behind Diego's scheduling mechanism.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/auction`.

There are two components in Diego that participate in auctions:

* **The Auctioneer** is responsible for holding auctions whenever a Task or
  LongRunningProcess needs to be scheduled. The Auctioneers run on the Diego
  "Brain" nodes, and there is only ever one active Auctioneer at a time
  (determined by acquiring a lock in Locket). The Auctioneer communicates with
  Reps on all Cells when holding an auction.
* **The Rep** represents a Diego Cell in the auction by making bids and, if
  picked as the winner, running the Task or LongRunningProcess. There is one
  Rep running on every Diego Cell.
