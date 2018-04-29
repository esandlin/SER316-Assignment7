/** 
 * CurrentProject.java
 * Created on 13.02.2003, 13:16:52 Alex
 * Package: net.sf.memoranda
 * @author Alex V. Alishevskikh, alex@openmechanics.net
 * Copyright (c) 2003 Memoranda Team. http://memoranda.sf.net
 */
package main.java.memoranda

import java.awt.event.ActionEvent
import java.awt.event.ActionListener
import java.util.Collection
import java.util.Vector
import main.java.memoranda.interfaces.INoteList
import main.java.memoranda.interfaces.IProject
import main.java.memoranda.interfaces.IResourcesList
import main.java.memoranda.interfaces.ITaskList
import main.java.memoranda.ui.AppFrame
import main.java.memoranda.util.Context
import main.java.memoranda.util.CurrentStorage
import main.java.memoranda.util.IStorage

/** 
 */
/*$Id: CurrentProject.java,v 1.6 2005/12/01 08:12:26 alexeya Exp $*/
class CurrentProject {
	static IProject _project = null
	static ITaskList _tasklist = null
	static INoteList _notelist = null
	static IResourcesList _resources = null
	static Vector projectListeners = new Vector()
	static final Void static_initializer = {
		{
			var String prjId = (Context::get("LAST_OPENED_PROJECT_ID") as String)
			if (prjId === null) {
				prjId = "__default"
				Context::put("LAST_OPENED_PROJECT_ID", prjId)
			}
			// ProjectManager.init();
			_project = ProjectManager::getProject(prjId)
			if (_project === null) {
				// alexeya: Fixed bug with NullPointer when LAST_OPENED_PROJECT_ID
				// references to missing project
				_project = ProjectManager::getProject("__default")
				if(_project === null) _project = ProjectManager::getActiveProjects().get(0) as IProject
				Context::put("LAST_OPENED_PROJECT_ID", _project.getID())
			}
			_tasklist = CurrentStorage::get().openTaskList(_project)
			_notelist = CurrentStorage::get().openNoteList(_project)
			_resources = CurrentStorage::get().openResourcesList(_project)
			AppFrame::addExitListener(([ActionEvent e|save()] as ActionListener))
		}
		null
	}

	def static IProject get() {
		return _project
	}

	def static ITaskList getTaskList() {
		return _tasklist
	}

	def static INoteList getNoteList() {
		return _notelist
	}

	def static IResourcesList getResourcesList() {
		return _resources
	}

	def static void set(IProject project) {
		if(project.getID().equals(_project.getID())) return;
		var ITaskList newtasklist = CurrentStorage::get().openTaskList(project)
		var INoteList newnotelist = CurrentStorage::get().openNoteList(project)
		var IResourcesList newresources = CurrentStorage::get().openResourcesList(project)
		notifyListenersBefore(project, newnotelist, newtasklist, newresources)
		_project = project
		_tasklist = newtasklist
		_notelist = newnotelist
		_resources = newresources
		notifyListenersAfter()
		Context::put("LAST_OPENED_PROJECT_ID", project.getID())
	}

	def static void addProjectListener(IProjectListener pl) {
		projectListeners.add(pl)
	}

	def static Collection getChangeListeners() {
		return projectListeners
	}

	def private static void notifyListenersBefore(IProject project, INoteList nl, ITaskList tl, IResourcesList rl) {
		for (var int i = 0; i < projectListeners.size(); i++) {
			((projectListeners.get(i) as IProjectListener)).projectChange(project, nl, tl, rl)
		/*DEBUGSystem.out.println(projectListeners.get(i));*/
		}
	}

	def private static void notifyListenersAfter() {
		for (var int i = 0; i < projectListeners.size(); i++) {
			((projectListeners.get(i) as IProjectListener)).projectWasChanged()
		}
	}

	def static void save() {
		var IStorage storage = CurrentStorage::get()
		storage.storeNoteList(_notelist, _project)
		storage.storeTaskList(_tasklist, _project)
		storage.storeResourcesList(_resources, _project)
		storage.storeProjectManager()
	}

	def static void free() {
		_project = null
		_tasklist = null
		_notelist = null
		_resources = null
	}
}
