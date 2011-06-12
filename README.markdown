# Gauge, A live status viewer for Rubinius

Gauge is a non-database backed Rails 3.0 application that reads a heap dump from the Rubinius VM and then displays the heap dump in a manner which allows you to interact with the heap snapshot.

## Creating a Heap Dump

Following the instructions from the "Memory Analysis" section of the Rubinius documentation (http://rubini.us/doc/en/tools/memory-analysis/), prepare a dump file.  Here is a brief overview of the process. From the docs:

Rubinius provides access to the VM via an agent interface. The agent opens a network socket and responds to commands issued by the console program. The agent must be started with the program.

```bash
rbx -Xagent.start <script name>
```

Connect to the agent using the rbx console. This program opens an interactive session with the agent running inside the VM. Commands are issued to the agent. In this case we are saving a heap dump for offline analysis.

```bash
$ rbx console
VM: rbx -Xagent.start leak.rb tcp://127.0.0.1:5549 1024 100000000
Connecting to VM on port 60544
Connected to localhost:60544, host type: x86_64-apple-darwin10.5.0
console> set system.memory.dump heap.dump
console> exit
```

The command is set system.memory.dump <filename>. The heap dump file is written to the current working directory for the program running the agent.

## Configuring Gauge

Set the ENV['DUMP'] environment variable in config/environment.rb, pointing to a heap dump file you want to analyze.

Run the Gauge app with:

```bash
rails server
```

and you will be greeted with a menu.  Enjoy!

## Details

Most recently tested with:

```bash
rubinius 2.0.0dev (1.8.7 96146df9 yyyy-mm-dd JI) [x86_64-apple-darwin10.7.3]
```
