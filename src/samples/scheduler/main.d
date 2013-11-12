import dquick.algorithms.scheduler;
import std.stdio;
import core.time;

class SomeTask
{
	void execute(Duration time, Duration step, ulong iter)
	{
		Duration appTime = time - TickDuration.appOrigin;
		writeln("SomeTask.execute: time=", appTime, ", step=", step, ", iter=", iter);
	}
}

void main()
{
	Scheduler sched = new Scheduler();
	
	SomeTask task = new SomeTask();
	sched.addTask(Duration.zero, dur!"seconds"(0), 5, &task.execute);
	
	while((TickDuration.currSystemTick - TickDuration.appOrigin).seconds < 3)
	{
		// do something complex...
	}
	
	sched.destroy();
}
